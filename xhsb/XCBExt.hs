{-# OPTIONS -ffi #-}
module XCBExt(request, requestWithReply) where

import XCB
import Control.Exception
import System.IO.Unsafe(unsafeInterleaveIO)
import Foreign

import Control.Monad.State
import Data.Generics

readSize :: Storable a => Int -> ForeignPtr p -> StateT Int IO a
readSize size p = do
    last <- get
    let cur = (last + size - 1) .&. (-size)
    put $ cur + size
    liftIO $ unsafeInterleaveIO $ withForeignPtr p $ \p'-> peek $ plusPtr p' cur

retTypeM :: Monad m => m a -> a
retTypeM _ = undefined

readGenericM :: Storable a => ForeignPtr p -> StateT Int IO a
readGenericM p = action
    where action = readSize (sizeOf $ retTypeM action) p

readBoolM :: ForeignPtr p -> StateT Int IO Bool
readBoolM p = do
    v <- readSize 1 p
    return $ (v :: Word8) /= 0

readReply :: Data reply => ForeignPtr p -> IO reply
readReply p = ret
    where
        ret = evalStateT (fromConstrM reader c) 0
        reader :: Typeable a => StateT Int IO a
        reader = fail "no reader for this type"
            `extR` (readBoolM p)
            `extR` (readGenericM p :: StateT Int IO Word8)
            `extR` (readGenericM p :: StateT Int IO Word16)
            `extR` (readGenericM p :: StateT Int IO Word32)
        c = indexConstr (dataTypeOf $ retTypeM ret) 1

foreign import ccall "X11/XCB/xcbext.h XCBWaitForReply" _waitForReply :: Ptr XCBConnection -> Word32 -> Ptr (Ptr XCBGenericError) -> IO (Ptr Word32)

request = throwIf (== 0) (const "couldn't send request")

requestWithReply :: Data reply => Ptr XCBConnection -> IO Word32 -> IO reply
requestWithReply c req = do
    cookie <- request req
    unsafeInterleaveIO $ throwIfNull "couldn't get reply" (_waitForReply c cookie nullPtr) >>= newForeignPtr finalizerFree >>= readReply
