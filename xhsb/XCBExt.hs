{-# OPTIONS -ffi #-}
module XCBExt(Readable(..), ReplyReader, readSize, readString, request, requestWithReply) where

import XCB
import Control.Exception
import System.IO.Unsafe(unsafeInterleaveIO)
import Foreign
import CForeign
import Control.Monad.Reader
import Control.Monad.State
import Debug.Trace

trace' s = trace $ " * " ++ s

type ReplyReader a = StateT Int (ReaderT (ForeignPtr Word32) IO) a

class Readable a where
    replyRead :: ReplyReader a
    replyReadLen :: Enum n => n -> ReplyReader [a]
    replyReadLen n = sequence $ replicate (fromEnum n) $ replyRead

instance Readable Bool where replyRead = readBool
instance Readable Word8 where replyRead = readStorable
instance Readable Word16 where replyRead = readStorable
instance Readable Word32 where replyRead = readStorable
instance Readable Int8 where replyRead = readStorable
instance Readable Int16 where replyRead = readStorable
instance Readable Int32 where replyRead = readStorable

readSize :: Storable a => Int -> ReplyReader a
readSize size = do
    last <- get
    let cur = (last + size - 1) .&. (-size)
    put $ cur + size
    p <- return . trace' "read pointer" =<< ask
    liftIO $ liftIO $ unsafeInterleaveIO $ withForeignPtr p $ \p'-> trace' "peek" $ peek $ plusPtr p' cur

retTypeM :: Monad m => m a -> a
retTypeM _ = undefined

readStorable :: Storable a => ReplyReader a
readStorable = action
    where action = readSize (sizeOf $ retTypeM action)

readBool :: ReplyReader Bool
readBool = (replyRead :: ReplyReader Word8) >>= return . toBool

readString :: Enum n => n -> ReplyReader String
readString n = do
    cur <- get
    put $ cur + fromEnum n
    p <- ask
    liftIO $ liftIO $ unsafeInterleaveIO $ withForeignPtr p $ \p'-> peekCStringLen (plusPtr p' cur, fromEnum n)

foreign import ccall "X11/XCB/xcbext.h XCBWaitForReply" _waitForReply :: Ptr XCBConnection -> Word32 -> Ptr (Ptr XCBGenericError) -> IO (Ptr Word32)

request :: IO Word32 -> IO Word32
request = return . trace' "sent request" =<< throwIf (== 0) (const "couldn't send request")

repeatIO :: IO a -> IO [a]
repeatIO f = unsafeInterleaveIO $ do x <- f; xs <- repeatIO f; return (x:xs)

requestWithReply :: Ptr XCBConnection -> ReplyReader reply -> IO Word32 -> IO [reply]
requestWithReply c readReply req = do
    cookie <- request req
    repeatIO $ throwIfNull "couldn't get reply" (_waitForReply c cookie nullPtr) >>= newForeignPtr finalizerFree >>= runReaderT (evalStateT readReply 0) >>= return . trace' "got reply"
