{-# OPTIONS -ffi #-}
module XProto(internAtom) where

import XCB
import XCBExt
import CForeign
import Foreign
import System.IO.Unsafe(unsafeInterleaveIO)

foreign import ccall "XProto.glue.h" _internAtom :: Ptr XCBConnection -> Word8 -> Word16 -> CString -> IO Word32

internAtom c onlyIfExists name = do
    reply <- requestWithReply c $ withCStringLen name (\(name, name_len)-> _internAtom c (if onlyIfExists then 1 else 0) (toEnum name_len) name)
    unsafeInterleaveIO $ withForeignPtr reply (\replyPtr-> peekElemOff replyPtr 2)
