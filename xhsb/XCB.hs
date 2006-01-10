{-# OPTIONS -fglasgow-exts -ffi #-}
module XCB(XCBConnection, XCBGenericError, connect, disconnect, withConnection) where

import Control.Exception
import CForeign
import Foreign

data XCBConnection
data XCBGenericError

foreign import ccall "X11/XCB/xcb.h XCBConnect" _connect :: CString -> Ptr CInt -> IO (Ptr XCBConnection)
foreign import ccall "X11/XCB/xcb.h XCBDisconnect" disconnect :: Ptr XCBConnection -> IO ()

connect display = withCString display (\displayPtr -> alloca (\screenPtr -> do
    c <- throwIfNull "connect failed" $ _connect displayPtr screenPtr
    screen <- peek screenPtr
    return (c, fromEnum screen)
    ))

withConnection display = bracket (connect display) (disconnect . fst) . uncurry
