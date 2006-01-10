{-# OPTIONS -fglasgow-exts -ffi #-}
module XProto(internAtom, Atom, InternAtomReply(..)) where

import XCB
import XCBExt
import CForeign
import Foreign
import Data.Generics

foreign import ccall "XProto.glue.h" _internAtom :: Ptr XCBConnection -> Word8 -> Word16 -> CString -> IO Word32

type Atom = Word32

data InternAtomReply = InternAtomReply { internAtomResponseType :: Word8, internAtomSequence :: Word16, internAtomLength :: Word32, internAtomAtom :: Atom }
    deriving (Typeable, Data)

internAtom :: Ptr XCBConnection -> Bool -> String -> IO InternAtomReply
internAtom c onlyIfExists name =
    requestWithReply c $ withCStringLen name (\(name, name_len)-> _internAtom c (fromBool onlyIfExists) (toEnum name_len) name)
