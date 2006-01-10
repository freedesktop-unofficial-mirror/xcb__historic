{-# OPTIONS -ffi #-}
module XCBExt(ReplyReader, readSize, readStorable, readBool, request, requestWithReply) where

import XCB
import Control.Exception
import System.IO.Unsafe(unsafeInterleaveIO)
import Foreign
import Control.Monad.Reader
import Control.Monad.State
import Debug.Trace

trace' s = trace $ " * " ++ s

type ReplyReader a = StateT Int (ReaderT (ForeignPtr Word32) IO) a

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
readBool = do
    v <- readSize 1
    return $ (v :: Word8) /= 0

foreign import ccall "X11/XCB/xcbext.h XCBWaitForReply" _waitForReply :: Ptr XCBConnection -> Word32 -> Ptr (Ptr XCBGenericError) -> IO (Ptr Word32)

request :: IO Word32 -> IO Word32
request = return . trace' "sent request" =<< throwIf (== 0) (const "couldn't send request")

requestWithReply :: Ptr XCBConnection -> ReplyReader reply -> IO Word32 -> IO reply
requestWithReply c readReply req = do
    cookie <- request req
    unsafeInterleaveIO $ trace' "got reply" $ throwIfNull "couldn't get reply" (_waitForReply c cookie nullPtr) >>= newForeignPtr finalizerFree >>= runReaderT (evalStateT readReply 0)
