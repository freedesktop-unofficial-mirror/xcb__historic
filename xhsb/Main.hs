module Main where

import XCB
import XProto
import Monad

main = withConnection "" $ \c screen -> do
        putStrLn $ "screen: " ++ (show screen)
        atoms <- mapM (internAtom c True) names
        zipWithM_ (\name atom-> putStrLn $ name ++ ": " ++ (show atom)) names atoms
    where names = ["this atom name doesn't exist", "PRIMARY", "SECONDARY", "Public domain font.  Share and enjoy."]
