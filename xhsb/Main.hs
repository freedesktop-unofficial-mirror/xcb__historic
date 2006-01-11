module Main where

import XCB
import XProto
import Monad

main = withConnection "" $ \c screen -> do
        putStrLn $ "screen: " ++ (show screen)
        atoms <- mapM (internAtom c True) names
        fonts <- listFontsWithInfo c 5 "-daewoo-*"
        zipWithM_ (\name atom-> putStrLn $ name ++ ": " ++ (show $ internAtomAtom atom)) names atoms
        mapM (print . name) fonts
    where names = ["this atom name doesn't exist", "PRIMARY", "SECONDARY", "Public domain font.  Share and enjoy."]
