The *.txt files were copied from

	http://www.unicode.org/Public/5.1.0/ucd

and subdirectories 'extracted' and 'auxiliary' as of Unicode 5.1.0 (March 2008).

The big file, Unihan.txt (28 MB, 5.8 MB zip) was not included due to space
considerations.  Also NOT included were any *.html files and *Test.txt files.

To be 8.3 filesystem friendly, the names of some of the input files have been
changed from the values that are in the Unicode DB:

mv PropertyValueAliases.txt PropValueAliases.txt
mv NamedSequencesProv.txt NamedSqProv.txt
mv DerivedAge.txt DAge.txt
mv DerivedCoreProperties.txt DCoreProperties.txt
mv DerivedNormalizationProps.txt DNormalizationProps.txt
mv extracted/DerivedBidiClass.txt extracted/DBidiClass.txt
mv extracted/DerivedBinaryProperties.txt extracted/DBinaryProperties.txt
mv extracted/DerivedCombiningClass.txt extracted/DCombiningClass.txt
mv extracted/DerivedDecompositionType.txt extracted/DDecompositionType.txt
mv extracted/DerivedEastAsianWidth.txt extracted/DEastAsianWidth.txt
mv extracted/DerivedGeneralCategory.txt extracted/DGeneralCategory.txt
mv extracted/DerivedJoiningGroup.txt extracted/DJoinGroup.txt
mv extracted/DerivedJoiningType.txt extracted/DJoinType.txt
mv extracted/DerivedLineBreak.txt extracted/DLineBreak.txt
mv extracted/DerivedNumericType.txt extracted/DNumType.txt
mv extracted/DerivedNumericValues.txt extracted/DNumValues.txt

The names of files, such as test files, that are not used by mktables are not
changed, and will not work correctly on 8.3 filesystems.

The file 'version' should exist and be a single line with the Unicode version,
like
5.1.0

NOTE: If you modify the input file set you should also run
 
    mktables -makelist
    
which will recreate the mktables.lst file which is used to speed up
the build process.    

FOR PUMPKINS

The files are inter-related.  If you take the latest UnicodeData.txt, for example,
but leave the older versions of other files, there can be subtle problems.

The *.pl files are generated from the *.txt files by the mktables script,
more recently done during the Perl build process, but if you want to try
the old manual way:
	
	cd lib/unicore
	cp .../UnicodeOriginal/*.txt .
	rm NormalizationTest.txt Unihan.txt Derived*.txt
	p4 edit Properties *.pl */*.pl
	perl ./mktables
	p4 revert -a
	cd ../..
	perl Porting/manicheck

You need to update version by hand

	p4 edit version
	...
	
If any new (or deleted, unlikely but not impossible) *.pl files are indicated:

	cd lib/unicore
	p4 add ...
	p4 delete ...
	cd ../...
	p4 edit MANIFEST
	...

And finally:

	p4 submit

-- 
jhi@iki.fi; updated by nick@ccl4.org
