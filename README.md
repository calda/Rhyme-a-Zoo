# Rhyme-a-Zoo
<b>Rhyme a Zoo for iOS</b> </br>
Developed by Cal Stephens  </br>
for Walter Evans at Georgia Regents University

##A note to future developers
If there comes a time where somebody must perform maintinence on Rhyme a Zoo, <i>my condolences</i>. Rhyme a Zoo is written in Swift 1.2, which is only supported in Xcode 6. Xcode 7+ requires the use of Swift 2, which is not syntax-compatible.


You have two options:
- Find a download for Xcode 6.4 (shouldn't be too tricky, but it won't be supported forever)
- Update to Swift 2

<b>Updating to Swift 2 is not a trivial task.</b> <br> 
SQLite.swift (the library I use to access the SQL database from the original PC version) has signifigant changes between the Swift 1.2 and Swift 2 versions, meaning a rewrite of the RZQuizDatabase class will be necessary. All of these changes will need to be tested and verified. 
<br>
##tl;dr: Use Xcode 6.4 if at all possible.
Otherwise, I'm sorry.
