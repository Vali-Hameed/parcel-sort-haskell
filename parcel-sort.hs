module Main where

import System.IO (readFile, writeFile)
import System.Directory (doesFileExist) -- Used to check for file existence instead of catch 
import Data.Char (isDigit, isAlphaNum, toLower)

-- Defines the different categories of mail. 
-- Deriving 'Ord' automatically orders these from left to right: 
-- LargeParcel < SmallParcel < LargeLetter < SmallLetter < Rejected.
data MailType = LargeParcel | SmallParcel | LargeLetter | SmallLetter | Rejected 
    deriving (Show, Eq, Ord)

-- Represents a single piece of mail. 
-- The fields are ordered specifically so that deriving 'Ord' automatically 
-- sorts the items first by Destination, then by MailType, then by ID, etc.
data MailItem = MailItem String MailType String Int Int Int Int 
    deriving (Show, Eq, Ord)

-- Helper functions to extract data from MailItem using pattern matching 
getDest :: MailItem -> String
getDest (MailItem dest _ _ _ _ _ _) = dest

getType :: MailItem -> MailType
getType (MailItem _ mtype _ _ _ _ _) = mtype

getId :: MailItem -> String
getId (MailItem _ _ mid _ _ _ _) = mid

getWeight :: MailItem -> Int
getWeight (MailItem _ _ _ _ _ _ wt) = wt


-- Recursively splits a string by commas 
splitComma :: String -> [String]
splitComma [] = [""]
splitComma (c:cs)
    | c == ','  = "" : splitComma cs
    | otherwise = let (h:t) = splitComma cs in (c:h):t
-- Validates that the ID is between 1 and 6 digits.v
validId :: String -> Bool
validId s = length s >= 1 && length s <= 6 && all isDigit s
-- Validates that the destination is exactly 6 alphanumeric characters.
validDest :: String -> Bool
validDest s = length s == 6 && all isAlphaNum s
-- Validates that dimensions and weight fall within acceptable positive ranges.
validDims :: Int -> Int -> Int -> Int -> Bool
validDims w h d wt = w > 0 && w < 10000 &&
                     h > 0 && h < 10000 &&
                     d > 0 && d < 10000 &&
                     wt > 0 && wt < 100000
-- Categorizes a piece of mail based on its dimensions and weight.
-- It checks conditions from the strictest (Rejected) to the broadest (LargeParcel).
classify :: Int -> Int -> Int -> Int -> MailType
classify w h d wt
    | wt > 20000 || (w + h + d) > 3000 = Rejected
    | w <= 240 && h <= 165 && d <= 5 && wt <= 100 = SmallLetter
    | w <= 353 && h <= 250 && d <= 25 && wt <= 750 = LargeLetter
    | w <= 450 && h <= 350 && d <= 160 && wt <= 2000 = SmallParcel
    | otherwise = LargeParcel

-- Safely parses a string into an Int if all characters are digits
parseNumber :: String -> Maybe Int
parseNumber s
    | not (null s) && all isDigit s = Just (read s) 
    | otherwise = Nothing

-- Parses a numbered line of text into a MailItem.
-- Returns (Right (Just MailItem)) on success, (Right Nothing) for blank lines,
-- and (Left lineNumber) if any formatting or validation fails.
parseLine :: (Int, String) -> Either Int (Maybe MailItem)
parseLine (lineNum, line)
    | null line = Right Nothing 
    | otherwise = case splitComma line of
        [idStr, wStr, hStr, dStr, wtStr, destStr] ->
            if validId idStr && validDest destStr
            then case (parseNumber wStr, parseNumber hStr, parseNumber dStr, parseNumber wtStr) of
                (Just w, Just h, Just d, Just wt) ->
                    if validDims w h d wt
                    then Right $ Just $ MailItem (map toLower destStr) (classify w h d wt) idStr w h d wt
                    else Left lineNum
                _ -> Left lineNum
            else Left lineNum
        _ -> Left lineNum

-- Recursively processes a list of numbered lines. 
-- Halts and returns the line number immediately if it encounters an error (Left).
processLines :: [(Int, String)] -> Either Int [MailItem]
processLines [] = Right []
processLines (x:xs) = case parseLine x of
    Left errNum -> Left errNum
    Right Nothing -> processLines xs
    Right (Just item) -> case processLines xs of
        Left errNum -> Left errNum
        Right items -> Right (item : items)


-- A classic quicksort using list comprehensions 
quickSort :: [MailItem] -> [MailItem]
quickSort [] = []
quickSort (x:xs) = 
    let smaller = quickSort [y | y <- xs, y <= x]
        larger  = quickSort [y | y <- xs, y > x]
    in smaller ++ [x] ++ larger

-- Takes a sorted list of mail and groups items with identical destinations together into sublists.
groupDestinations :: [MailItem] -> [[MailItem]]
groupDestinations [] = []
groupDestinations (x:xs) = 
    let sameDest = takeWhile (\y -> getDest y == getDest x) (x:xs)
        rest     = dropWhile (\y -> getDest y == getDest x) (x:xs)
    in sameDest : groupDestinations rest


-- Greedily packs items into a bundle without exceeding a specified weight limit.
-- Returns a tuple containing the items in the bundle, and the remaining unpacked items.
fillBundle :: Int -> [MailItem] -> [MailItem] -> [MailItem] -> ([MailItem], [MailItem])
fillBundle _ [] bundle rest = (reverse bundle, reverse rest)
fillBundle remWeight (x:xs) bundle rest
    | getWeight x <= remWeight = fillBundle (remWeight - getWeight x) xs (x:bundle) rest
    | otherwise = fillBundle remWeight xs bundle (x:rest)

-- Recursively calls fillBundle to pack all items for a destination into multiple 20,000g bundles.
bundleAll :: [MailItem] -> [[MailItem]]
bundleAll [] = []
bundleAll items =
    let (bundle, rest) = fillBundle 20000 items [] []
    in bundle : bundleAll rest



-- Combines a list of strings into a single string separated by commas.
joinComma :: [String] -> String
joinComma [] = ""
joinComma [x] = x
joinComma (x:xs) = x ++ "," ++ joinComma xs

-- Formats a single bundle into the required text format
formatBundle :: Int -> [MailItem] -> String
formatBundle seqNum bundle =
    let dest = getDest (head bundle)
        ids = map getId bundle
    in joinComma (dest : show seqNum : ids)

-- Maps over a list of bundles for a single destination, numbering them sequentially from 1.
formatDestGroup :: [[MailItem]] -> [String]
formatDestGroup bundles = zipWith formatBundle [1..] bundles

-- Coordinates the entire data processing pipeline for the functional core.
processAll :: [MailItem] -> [String]
processAll items =
    let deliverable = [x | x <- items, getType x /= Rejected] -- Filter out rejected mail
        sortedItems = quickSort deliverable -- Sort by dest then type
        groupedItems = groupDestinations sortedItems -- Group by destination
        -- Bundle each group and format the resulting bundles into strings
    in concat (map (\group -> formatDestGroup (bundleAll group)) groupedItems)

-- The program entry point. Handles all file reading/writing and initiates the core logic.
main :: IO ()
main = do
    exists <- doesFileExist "input.txt"
    if exists
        then do
            content <- readFile "input.txt" 
            let linesOfFile = lines content
                -- Strip any carriage returns manually to ensure compatibility regardless of os line endings
                cleanLines = map (\l -> [c | c <- l, c /= '\r']) linesOfFile
                numbered = zip [1..] cleanLines
            -- Attempt to process the lines. If it hits an error, print the line number.
            case processLines numbered of
                Left errLine -> putStrLn $ "Invalid file, error on line " ++ show errLine ++ "."
                Right items -> do
                    let outputLines = processAll items
                        outputStr = unlines outputLines 
                    writeFile "output.txt" outputStr
        else putStrLn "Input file not found."