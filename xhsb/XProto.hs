{-# OPTIONS -fglasgow-exts -ffi #-}
module XProto(internAtom, Atom, InternAtomReply(..), listFontsWithInfo, ListFontsWithInfoReply(..)) where

import XCB
import XCBExt
import CForeign
import Foreign
import Control.Monad.State

type Atom = Word32

data CharInfo = CharInfo Int16 Int16 Int16 Int16 Int16 Word16
    deriving Show

instance Readable CharInfo where
    replyRead = do
        left_side_bearing <- replyRead
        right_side_bearing <- replyRead
        character_width <- replyRead
        ascent <- replyRead
        descent <- replyRead
        attributes <- replyRead
        return $ CharInfo left_side_bearing right_side_bearing character_width ascent descent attributes

data FontProp = FontProp Atom Word32
    deriving Show

instance Readable FontProp where
    replyRead = do
        name <- replyRead
        value <- replyRead
        return $ FontProp name value

foreign import ccall "XProto.glue.h" _internAtom :: Ptr XCBConnection -> Word8 -> Word16 -> CString -> IO Word32
data InternAtomReply = InternAtomReply { internAtomResponseType :: Word8, internAtomSequence :: Word16, internAtomLength :: Word32, internAtomAtom :: Atom }
internAtom :: Ptr XCBConnection -> Bool -> String -> IO InternAtomReply
internAtom c onlyIfExists name =
        (requestWithReply c reader $ withCStringLen name (\(name, name_len)-> _internAtom c (fromBool onlyIfExists) (toEnum name_len) name))
        >>= return . head
    where reader = do
            responseType <- replyRead
            sequence <- replyRead
            length <- replyRead
            atom <- replyRead
            return $ InternAtomReply responseType sequence length atom

foreign import ccall "XProto.glue.h" _ListFontsWithInfo :: Ptr XCBConnection -> Word16 -> Word16 -> CString -> IO Word32
data ListFontsWithInfoReply = ListFontsWithInfoReply { min_bounds :: CharInfo, max_bounds :: CharInfo, min_char_or_byte2 :: Word16, max_char_or_byte2 :: Word16, default_char :: Word16, draw_direction :: Word8, min_byte1 :: Word8, max_byte1 :: Word8, all_chars_exist :: Bool, font_ascent :: Int16, font_descent :: Int16, replies_hint :: Word32, properties :: [FontProp], name :: String }
    deriving Show
listFontsWithInfo :: Ptr XCBConnection -> Word16 -> String -> IO [ListFontsWithInfoReply]
listFontsWithInfo c max_names pattern =
        (requestWithReply c reader $ withCStringLen pattern $ \(pattern, pattern_len)-> _ListFontsWithInfo c max_names (toEnum pattern_len) pattern)
        >>= return . takeWhile (\f-> name f /= "")
    where
        reader = do
            modify (+ 1)
            name_len <- replyRead :: ReplyReader Word8
            modify (+ 6)
            min_bounds <- replyRead
            modify (+ 4)
            max_bounds <- replyRead
            modify (+ 4)
            min_char_or_byte2 <- replyRead
            max_char_or_byte2 <- replyRead
            default_char <- replyRead
            properties_len <- replyRead :: ReplyReader Word16
            draw_direction <- replyRead
            min_byte1 <- replyRead
            max_byte1 <- replyRead
            all_chars_exist <- replyRead
            font_ascent <- replyRead
            font_descent <- replyRead
            replies_hint <- replyRead
            properties <- replyReadLen properties_len
            modify (\n-> (n + 3) .&. (-4))
            name <- readString name_len
            return $ ListFontsWithInfoReply min_bounds max_bounds min_char_or_byte2 max_char_or_byte2 default_char draw_direction min_byte1 max_byte1 all_chars_exist font_ascent font_descent replies_hint properties name
