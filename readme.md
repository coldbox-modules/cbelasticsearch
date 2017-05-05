# Ortus Module Template
This module template will allow you to have a test harness, build scripts, travis integration and automatic ForgeBox publishing for Ortus Modules.

## LICENSE
Apache License, Version 2.0.


INSTRUCTIONS
============

You will build your module under the `modules` folder.

## Version Bumps
When you are ready to release a new version of your module you can run the following command `bump --major --minor --patch`.

This will bump the version in the root `box.json` but also the `.module.properties` file, commit it to the repo and it will be tagged.  This can then be pushed so the automated integrations can occur.

## Automated Test Suite
We have provided an automated test suite in your `tests` folder. Spice up as needed.

## ANT Build
The ANT build for this project is under `workbench/build.xml`. You can modify it as you see fit.

## Travis Integration
We have added Travis Integration for your module. Open the `.travis.yml` to spice it up.

## Unified Workbench
The module template leverages the Ortus Unified workbench for testing in all CFML engines and auto-publishing to ForgeBox.  Please update the following files for automatic builds and publishing:

* `.module.properties`
* `.travis.yml`

## API Docs

This template has the ability to generate API docs for your module. This is located in the `apidocs` folder.  All you need to do is open the `Application.cfc` and change the name of the `cbModule` placeholder to the name of your module.


********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************
####HONOR GOES TO GOD ABOVE ALL
Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

>"Therefore being justified by faith, we have peace with God through our Lord Jesus Christ:
By whom also we have access by faith into this grace wherein we stand, and rejoice in hope of the glory of God.
And not only so, but we glory in tribulations also: knowing that tribulation worketh patience;
And patience, experience; and experience, hope:
And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the 
Holy Ghost which is given unto us. ." Romans 5:5

###THE DAILY BREAD
 > "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12