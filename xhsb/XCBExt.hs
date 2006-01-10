{-# OPTIONS -ffi #-}
module XCBExt(request, requestWithReply) where

import XCB
import Control.Exception
import System.IO.Unsafe(unsafeInterleaveIO)
import Foreign

foreign import ccall "X11/XCB/xcbext.h XCBWaitForReply" _waitForReply :: Ptr XCBConnection -> Word32 -> Ptr (Ptr XCBGenericError) -> IO (Ptr Word32)

request = throwIf (== 0) (const "couldn't send request")

requestWithReply c req = do
    cookie <- request req
    unsafeInterleaveIO $ throwIfNull "couldn't get reply" (_waitForReply c cookie nullPtr) >>= newForeignPtr finalizerFree
