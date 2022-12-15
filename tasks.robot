*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Download Input File
    Open robotsparebinindustries
    Accept Popup
    Read Orders File And Fill Form
    Zip Receipts
    [Teardown]    Close Opened Browser


*** Keywords ***
Open robotsparebinindustries
    ${secret}=    Get Secret    siteInformation
    Open Available Browser    ${secret}[url]

Download Input File
    Add heading    Enter the URL for the Orders File
    Add text input    excelPath    label=File Path
    ${filePath}=    Run dialog
    Download    ${filePath.excelPath}    overwrite=True

Read Orders File And Fill Form
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Fill and submit the form    ${order}
        Save Robot Preview as PDF    ${order}
        Wait Until Keyword Succeeds    10x    2s    Submit Order
        Save Order as PDF    ${order}
        Add Preview to Receipt    ${order}
        Click Button    Order another robot
        Accept Popup
    END

Accept Popup
    Click Button    OK

Submit Order
    Click Button    Order
    Wait Until Element Is Visible    id:receipt

Fill and submit the form
    [Arguments]    ${order}
    Select From List By Index    id:head    ${order}[Head]
    Click Element    id:id-body-${order}[Body]
    Input Text    xpath=//input[@placeholder='Enter the part number for the legs']    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    Click Button    Preview

Save Order as PDF
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}Receipts${/}receipt_${order}[Order number].pdf

Save Robot Preview as PDF
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}Receipts${/}robotPreview_${order}[Order number].png

Add Preview to Receipt
    [Arguments]    ${order}
    ${receipt_pdf}=    Open Pdf    ${OUTPUT_DIR}${/}Receipts${/}receipt_${order}[Order number].pdf
    ${receipt_robotPreview}=    Create List
    ...    ${OUTPUT_DIR}${/}Receipts${/}receipt_${order}[Order number].pdf
    ...    ${OUTPUT_DIR}${/}Receipts${/}robotPreview_${order}[Order number].png
    Add Files To Pdf    ${receipt_robotPreview}    ${OUTPUT_DIR}${/}Receipts${/}receipt_${order}[Order number].pdf
    Close Pdf    ${receipt_pdf}
    Remove File    ${OUTPUT_DIR}${/}Receipts${/}robotPreview_${order}[Order number].png

Zip Receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}Receipts${/}    ${OUTPUT_DIR}${/}receipts.zip

Close Opened Browser
    Close Browser
