# LOI Discovery Interface

## Data and build process

Data is supplied by a CSV file that is defined in `properties.xml`. Currently, this is `data/data.csv`, which is an export from https://uvic.sharepoint.com/:x:/r/sites/HCMCHumanitiesComputingMediaCentreO/Shared%20Documents/LOI%20Discovery%20Interface/LegacyWebsiteAssetListSorted%209-9-26.xlsx?d=w31c513b0f5fd40faa94c7bf196105930&csf=1&web=1&e=AQudhc. To add data, change the SharePoint file, export to CSV, and either replace the current file or save the new file and change the filename in `properties.xml`. You can also edit the current `data.csv` file directly. 

The CSV is processed into `items.xml` using XSLT. A separate XML file is then created for each category in the Categories column and placed in `content/generated`. These XML files are then transformed into static HTML pages during the site build. The build process also generates cards for each item in the data file and puts those cards into the appropriate location in the `index.html` file. 

Any XML files in the `conent` directory are also processed into separate HTML pages with the site chrome as part of the build.

Run `ant fullBuild` or just `ant` to rebuild the whole site. If you want only part of the build process, run `ant convertDiscoveryData` to refresh the catalogue, `ant makeCategoryPages` to generate category page sources and HTML, or `ant makeLandingPage` to rebuild the index.html page. `ant productionReady` builds a version of the site with hashed CSS/JavaScript assets and validates the HTML. The `ant rsyncToLiveServer` target currently doesn't work.

After a full build, run `ant validateSite` to validate the 

## CSV columns

Keep the existing named columns and use a CSV editor that quotes fields containing commas, quotes, or newlines. An unnamed trailing column is supported. Additional columns, such as `HCMC`, are preserved in XML but do not appear on cards.

| Column | Purpose |
| --- | --- |
| `Number` | REQUIRED. Unique ID number. Must be a positive integer. |
| `Asset Name` | REQUIRED. Card title. |
| `Priority Level` | REQUIRED. Number 1–4; Determines the priority level of each item. 1 = high. 4 = low. |
| `Category` | REQUIRED. Category label for each item. |
| `Current URL` | OPTIONAL. URL for the item. Blank, TBD, or other unavailable values lead to a card that says "Link Unavailable". |
| `Notes` | NOT CURRENTLY PROCESSED. |
| `Image Filename` | OPTIONAL. image filename. Eg. `adachi.jpg`. Only available for priority 1 items. All images must be placed in the `content/images` directory. |
| `Image Alt Text` | OPTIONAL. image alt text. Use meaningful text if the image conveys information beyond the card title. |

Rows missing an ID, title, category, or valid priority do not produce cards or categories. Missing usable URLs will a warning but will not exclude items from the build. Duplicate nonblank numbers, malformed CSV quoting, and missing or duplicate named headings will cause the build to fail immediately. Rows with the wrong field count are reported and omitted. Empty or duplicate categories will cause category generation to fail.

