*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    ${url}=    Get Secret    credentials
    Log To Console    ${url}[robot_order_url]
    Open Available Browser    ${url}[robot_order_url]

Get orders from input Dialogs
    Add heading    Please input order-csv-link
    Add text input    order    label=order csv link
    ${response}=    Run dialog
    [Return]    ${response}

Get orders
    ${result}    Get orders from input Dialogs
    Download    ${result.order}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

Close the annoying modal
    Click element    xpath://button[@class="btn btn-dark"]

Fill the form
    [Arguments]    ${info}
    Select From List By Index    id:head    ${info}[Head]
    Click Element    xpath://input[@id="id-body-${info}[Body]"]
    Input Text    xpath://input[@placeholder="Enter the part number for the legs"]    ${info}[Legs]
    Input Text    id:address    ${info}[Address]

Preview the robot
    Click Element    id:preview

Submit the order
    Wait Until Keyword Succeeds    3x    0.5 sec    Run keywords    Click Element    id:order
    ...    AND    Wait Until Element Is Visible    id:order-another

Store the receipt as a PDF file
    [Arguments]    ${info}
    Wait Until Keyword Succeeds    1 min    1 sec    Wait Until Element Is Visible    id:receipt
    ${sreceipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sreceipt_html}    ${CURDIR}${/}outputfile${/}${info}.pdf
    [Return]    ${CURDIR}${/}outputfile${/}${info}.pdf

Take a screenshot of the robot
    [Arguments]    ${info}
    Screenshot    id:robot-preview    ${CURDIR}${/}outputfile${/}${info}.png
    [Return]    ${CURDIR}${/}outputfile${/}${info}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    @{info}    Create List    ${screenshot}
    Open Pdf    ${pdf}
    Add Files To Pdf    ${info}    ${pdf}    True
    Close Pdf    ${pdf}

Go to order another robot
    Click Element    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip
    ...    ${CURDIR}${/}outputfile
    ...    myresult.zip
