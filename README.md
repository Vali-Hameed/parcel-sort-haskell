# **Parcel Sort CLI Haskell**

This is a Haskell-based command-line application designed to process, classify, sort, and bundle mail items based on their physical dimensions, weight, and destination.


## **Features**

- **File-Based Processing:** The application automatically reads from an input.txt file. It writes the successfully processed and bundled mail to an output.txt file.

- **Data Validation:** The program ensures all data is strictly validated before processing.

* IDs must be between 1 and 6 digits long.

* Destinations must be exactly 6 alphanumeric characters.

* Dimensions and weights must fall within acceptable positive ranges.

- **Mail Classification:** Mail items are categorized based on their dimensions (width, height, depth) and weight. The categories include SmallLetter, LargeLetter, SmallParcel, LargeParcel, and Rejected.

* Items exceeding 20,000 weight units or 3,000 combined dimension units are automatically classified as Rejected.

- **Sorting and Grouping:** The application uses a custom QuickSort implementation to sort deliverable items. Items are grouped together by identical destinations.

- **Greedy Bundling:** Mail items heading to the same destination are packed into sequential bundles. The application ensures no single bundle exceeds a weight limit of 20,000.


## **Data Formats**

### **Input Format (input.txt)**

The application expects comma-separated values for each mail item on a new line. Blank lines are ignored. The expected format is:

ID, Width, Height, Depth, Weight, Destination


### **Output Format (output.txt)**

The application generates comma-separated bundles in the output file. Rejected mail is filtered out and excluded from the final output. The format for each bundled line is:

Destination, SequenceNumber, ID1, ID2, ID3...


## **Error Handling**

The program utilizes safe parsing and will halt execution if it detects formatting or validation errors.

- If a line contains invalid data or improper formatting, the program will terminate and print: Invalid file, error on line \[LineNumber].

- If the input.txt file is missing from the directory, the program will print: Input file not found.


## **Getting Started**

1. Ensure the Glasgow Haskell Compiler (GHC) is installed on your system.

2. Place your raw parcel data into a file named input.txt in the same directory as the executable.

3. Compile the code:\
   ```ghc -o parcel-sort parcel-sort.hs```

4. Run the executable:\
   ```./parcel-sort```

5. Check output.txt for your formatted bundles.
