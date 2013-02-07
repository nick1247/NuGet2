function Test-RemovingPackageFromProjectDoesNotRemoveIfInUse {
    # Arrange
    $p1 = New-ClassLibrary
    $p2 = New-ClassLibrary
    
    Install-Package Ninject -Project $p1.Name
    Assert-Reference $p1 Ninject
    
    Install-Package Ninject -Project $p2.Name
    Assert-Reference $p2 Ninject
    
    Uninstall-Package Ninject -Project $p1.Name
    
    Assert-Null (Get-ProjectPackage $p1 Ninject)
    Assert-Null (Get-AssemblyReference $p1 Ninject)
    Assert-SolutionPackage Ninject
}

function Test-RemovingPackageWithDependencyFromProjectDoesNotRemoveIfInUse {
    # Arrange
    $p1 = New-WebApplication
    $p2 = New-WebApplication
    
    $p1 | Install-Package jquery.Validation
    Assert-Package $p1 jquery.Validation
    Assert-Package $p1 jquery
    
    $p2 | Install-Package jquery.Validation
    Assert-Package $p1 jquery.Validation
    Assert-Package $p1 jquery
    
    $p1 | Uninstall-Package jquery.Validation
    $p1 | Uninstall-Package jquery
    
    Assert-Null (Get-ProjectPackage $p1 jquery.Validation)
    Assert-Null (Get-ProjectPackage $p1 jquery)
    Assert-SolutionPackage jquery.Validation
    Assert-SolutionPackage jquery
}

function Test-RemovePackageRemovesPackageFromSolutionIfNotInUse {
    # Arrange
    $p1 = New-WebApplication
    
    Install-Package elmah -Project $p1.Name -Version 1.1
    Assert-Reference $p1 elmah
    Assert-SolutionPackage elmah
    
    Uninstall-Package elmah -Project $p1.Name
    Assert-Null (Get-AssemblyReference $p1 elmah)
    Assert-Null (Get-ProjectPackage $p1 elmah)
    Assert-Null (Get-SolutionPackage elmah)
}

function Test-UninstallingPackageWithConfigTransformWhenConfigReadOnly {
    # Arrange
    $p1 = New-WebApplication
    
    Install-Package elmah -Project $p1.Name -Version 1.1
    Assert-Reference $p1 elmah
    Assert-SolutionPackage elmah
    attrib +R (Get-ProjectItemPath $p1 web.config)
    
    Uninstall-Package elmah -Project $p1.Name
    Assert-Null (Get-AssemblyReference $p1 elmah)
    Assert-Null (Get-ProjectPackage $p1 elmah)
    Assert-Null (Get-SolutionPackage elmah)
}

function Test-VariablesPassedToUninstallScriptsAreValidWithWebSite {
    param(
        $context
    )
    
    # Arrange
    $p = New-WebSite

    Install-Package PackageWithScripts -Project $p.Name -Source $context.RepositoryRoot

    # This asserts install.ps1 gets called with the correct project reference and package
    Assert-Reference $p System.Windows.Forms

     # Act
    Uninstall-Package PackageWithScripts -Project $p.Name
    Assert-Null (Get-AssemblyReference $p System.Windows.Forms)
}

function Test-UninstallPackageWithNestedContentFiles {
    param(
        $context
    )

    # Arrange
    $p = New-WebApplication
    Install-Package NestedFolders -Project $p.Name -Source $context.RepositoryPath

    # Act    
    Uninstall-Package NestedFolders -Project $p.Name

    # Assert
    Assert-Null (Get-ProjectItem $p a)
    Assert-Null (Get-ProjectItem $p a\b)
    Assert-Null (Get-ProjectItem $p a\b\c)
    Assert-Null (Get-ProjectItem $p a\b\c\test.txt)
}

function Test-SimpleFSharpUninstall {
    # Arrange
    $p = New-FSharpLibrary
    
    # Act
    Install-Package Ninject -Project $p.Name 
    Assert-Reference $p Ninject
    Assert-Package $p Ninject
    Assert-SolutionPackage Ninject
    Uninstall-Package Ninject -Project $p.Name
    
    # Assert
    Assert-Null (Get-ProjectPackage $p Ninject)
    Assert-Null (Get-AssemblyReference $p Ninject)
    Assert-Null (Get-SolutionPackage Ninject)
}

function Test-FSharpDependentPackageUninstall {
    # Arrange
    $p = New-FSharpLibrary
    $p | Install-Package -Source $context.RepositoryRoot PackageWithDependencyOnPrereleaseTestPackage

    # Act & Assert
    Assert-Throws { $p | Uninstall-Package PreReleaseTestPackage } "Unable to uninstall 'PreReleaseTestPackage 1.0.0' because 'PackageWithDependencyOnPrereleaseTestPackage 1.0' depends on it."
}

function Test-UninstallPackageThatIsNotInstalledThrows {
    # Arrange
    $p = New-ClassLibrary

    # Act & Assert
    Assert-Throws { $p | Uninstall-Package elmah } "Unable to find package 'elmah'."
}

function Test-UninstallPackageThatIsInstalledInAnotherProjectThrows {
    # Arrange
    $p1 = New-ClassLibrary
    $p2 = New-ClassLibrary
    $p1 | Install-Package elmah -Version 1.1

    # Act & Assert
    Assert-Throws { $p2 | Uninstall-Package elmah } "Unable to find package 'elmah' in '$($p2.Name)'."
}

function Test-UninstallSolutionOnlyPackage {
    param(
        $context
    )

    # Arrange
    $p = New-MvcApplication
    $p | Install-Package SolutionOnlyPackage -Source $context.RepositoryRoot

    Assert-SolutionPackage SolutionOnlyPackage 2.0

    Uninstall-Package SolutionOnlyPackage

    Assert-Null (Get-SolutionPackage SolutionOnlyPackage 2.0)
}

function Test-UninstallPackageProjectLevelPackageThatsOnlyInstalledAtSolutionLevel {
    # Arrange
    $p = New-ClassLibrary
    $p | Install-Package elmah -Version 1.1
    Remove-ProjectItem $p packages.config
    
    Assert-SolutionPackage elmah
    Assert-Null (Get-ProjectPackage $p elmah)

    # Act
    $p | Uninstall-Package elmah

    # Assert
    Assert-NoSolutionPackage elmah -Version 1.1
}

function Test-UninstallSpecificPackageThrowsIfNotInstalledInProject {
    # Arrange
    $p1 = New-ClassLibrary
    $p2 = New-FSharpLibrary
    $p1 | Install-Package Antlr -Version 3.1.1
    $p2 | Install-Package Antlr -Version 3.1.3.42154

    # Act
    Assert-Throws { $p2 | Uninstall-Package Antlr -Version 3.1.1 } "Unable to find package 'Antlr 3.1.1' in '$($p2.Name)'."
}

function Test-UninstallSpecificVersionOfPackage {
    # Arrange
    $p1 = New-ClassLibrary
    $p2 = New-FSharpLibrary
    $p1 | Install-Package Antlr -Version 3.1.1
    $p2 | Install-Package Antlr -Version 3.1.3.42154

    # Act
    $p1 | Uninstall-Package Antlr -Version 3.1.1

    # Assert
    Assert-Null (Get-ProjectPackage $p1 Antlr 3.1.1)
    Assert-Null (Get-SolutionPackage Antlr 3.1.1)
    Assert-SolutionPackage Antlr 3.1.3.42154
}

function Test-UninstallSpecificVersionOfProjectLevelPackageFromSolutionLevel {        
    # Arrange
    $p1 = New-ClassLibrary
    $p2 = New-FSharpLibrary
    $p1 | Install-Package jQuery -Version 1.8.0
    $p2 | Install-Package jQuery -Version 1.8.2
    Remove-ProjectItem $p1 packages.config
    Remove-ProjectItem $p2 packages.config

    Assert-SolutionPackage jQuery 1.8.0
    Assert-SolutionPackage jQuery 1.8.2
    @($p1, $p2) | %{ Assert-Null (Get-ProjectPackage $_ jQuery) }

    Write-Host "Now uninstall package"

    # Act
    $p1 | Uninstall-Package jQuery -Version 1.8.0

    # Assert
    Assert-NoSolutionPackage jQuery 1.8.0
    Assert-SolutionPackage jQuery 1.8.2
}

function Test-UninstallAmbiguousProjectLevelPackageFromSolutionLevel {    
    # Arrange
    $p1 = New-ClassLibrary
    $p2 = New-FSharpLibrary
    $p1 | Install-Package Antlr -Version 3.1.1
    $p2 | Install-Package Antlr -Version 3.1.3.42154
    Remove-ProjectItem $p1 packages.config
    Remove-ProjectItem $p2 packages.config

    Assert-SolutionPackage Antlr 3.1.1
    Assert-SolutionPackage Antlr 3.1.3.42154
    @($p1, $p2) | %{ Assert-Null (Get-ProjectPackage $_ Antlr) }

    # Act
    Assert-Throws { $p1 | Uninstall-Package Antlr } "Unable to find 'Antlr' in '$($p1.Name)' and found multiple versions of 'Antlr' installed. Please specify a version."
}

function Test-UninstallSolutionOnlyPackageWhenAmbiguous {
    param(
        $context
    )

    # Arrange
    $p = New-MvcApplication
    Install-Package SolutionOnlyPackage -Version 1.0 -Source $context.RepositoryRoot
    Install-Package SolutionOnlyPackage -Version 2.0 -Source $context.RepositoryRoot

    Assert-SolutionPackage SolutionOnlyPackage 1.0
    Assert-SolutionPackage SolutionOnlyPackage 2.0

    Assert-Throws { Uninstall-Package SolutionOnlyPackage } "Found multiple versions of 'SolutionOnlyPackage' installed. Please specify a version."
}

function Test-UninstallPackageWorksWithPackagesHavingSameNames {
    #
    #  Folder1
    #     + ProjectA
    #     + ProjectB
    #  Folder2
    #     + ProjectA
    #     + ProjectC
    #  ProjectA
    #

    # Arrange
    $f = New-SolutionFolder 'Folder1'
    $p1 = $f | New-ClassLibrary 'ProjectA'
    $p2 = $f | New-ClassLibrary 'ProjectB'

    $g = New-SolutionFolder 'Folder2'
    $p3 = $g | New-ClassLibrary 'ProjectA'
    $p4 = $g | New-ConsoleApplication 'ProjectC'

    $p5 = New-ConsoleApplication 'ProjectA'

    # Act
    Get-Project -All | Install-Package elmah -Version 1.1
    $all = @( $p1, $p2, $p3, $p4, $p5 )
    $all | % { Assert-Package $_ elmah }

    Get-Project -All | Uninstall-Package elmah

    # Assert
    $all | % { Assert-Null (Get-ProjectPackage $_ elmah) }
}

function Test-UninstallPackageWithXmlTransformAndTokenReplacement {
    param(
        $context
    )

    # Arrange
    $p = New-WebApplication
    $p | Install-Package PackageWithXmlTransformAndTokenReplacement -Source $context.RepositoryRoot

    # Assert
    $ns = $p.Properties.Item("DefaultNamespace").Value
    $assemblyName = $p.Properties.Item("AssemblyName").Value
    $path = (Get-ProjectItemPath $p web.config)
    $content = [System.IO.File]::ReadAllText($path)
    $expectedContent = "type=`"$ns.MyModule, $assemblyName`""
    Assert-True ($content.Contains($expectedContent))

    # Act
    $p | Uninstall-Package PackageWithXmlTransformAndTokenReplacement
    $content = [System.IO.File]::ReadAllText($path)
    Assert-False ($content.Contains($expectedContent))
}

function Test-UninstallPackageAfterRenaming {
    param(
        $context
    )
    # Arrange
    $f = New-SolutionFolder 'Folder1' | New-SolutionFolder 'Folder2'
    $p0 = New-ClassLibrary 'ProjectX'
    $p1 = $f | New-ClassLibrary 'ProjectA'
    $p2 = $f | New-ClassLibrary 'ProjectB'

    # Act
    $p1 | Install-Package NestedFolders -Source $context.RepositoryPath 
    $p1.Name = "ProjectX"
    Uninstall-Package NestedFolders -Project Folder1\Folder2\ProjectX

    $p2 | Install-Package NestedFolders -Source $context.RepositoryPath 
    $f.Name = "Folder3"
    Uninstall-Package NestedFolders -Project Folder1\Folder3\ProjectB

    Assert-Null (Get-ProjectItem $p1 scripts\jquery-1.5.js)
    Assert-Null (Get-ProjectItem $p2 scripts\jquery-1.5.js)
}

function Test-UninstallDoesNotRemoveFolderIfNotEmpty {
    param(
        $context
    )
    # Arrange
    $p = New-WebApplication
    $p | Install-Package PackageWithFolder -Source $context.RepositoryRoot

    # Get the path to the foo folder
    $fooPath = (Join-Path (Split-Path $p.FullName) Foo)

    # Add 5 files to that folder (on disk but not in the project)
    0..5 | %{ "foo" | Out-File (Join-Path $fooPath "file$_.out") }

    Uninstall-Package PackageWithFolder

    Assert-Null (Get-ProjectPackage $p PackageWithFolder)
    Assert-Null (Get-SolutionPackage PackageWithFolder)
    Assert-PathExists $fooPath
}

function Test-WebSiteUninstallPackageWithPPCSSourceFiles {
    param(
        $context
    )
    # Arrange
    $p = New-WebSite
    
    # Act
    $p | Install-Package PackageWithPPCSSourceFiles -Source $context.RepositoryRoot    
    Assert-Package $p PackageWithPPCSSourceFiles
    Assert-SolutionPackage PackageWithPPCSSourceFiles
    Assert-NotNull (Get-ProjectItem $p App_Code\Foo.cs)
    Assert-NotNull (Get-ProjectItem $p App_Code\Bar.cs)

    # Assert
    $p | Uninstall-Package PackageWithPPCSSourceFiles
    Assert-Null (Get-ProjectItem $p App_Code\Foo.cs)
    Assert-Null (Get-ProjectItem $p App_Code\Bar.cs)
    Assert-Null (Get-ProjectItem $p App_Code)
}

function Test-WebSiteUninstallPackageWithPPVBSourceFiles {
    param(
        $context
    )
    # Arrange
    $p = New-WebSite
    
    # Act
    $p | Install-Package PackageWithPPVBSourceFiles -Source $context.RepositoryRoot    
    Assert-Package $p PackageWithPPVBSourceFiles
    Assert-SolutionPackage PackageWithPPVBSourceFiles
    Assert-NotNull (Get-ProjectItem $p App_Code\Foo.vb)
    Assert-NotNull (Get-ProjectItem $p App_Code\Bar.vb)

    # Assert
    $p | Uninstall-Package PackageWithPPVBSourceFiles
    Assert-Null (Get-ProjectItem $p App_Code\Foo.vb)
    Assert-Null (Get-ProjectItem $p App_Code\Bar.vb)
    Assert-Null (Get-ProjectItem $p App_Code)
}

function Test-WebSiteUninstallPackageWithNestedSourceFiles {
    param(
        $context
    )
    # Arrange
    $p = New-WebSite
    
    # Act
    $p | Install-Package netfx-Guard -Source $context.RepositoryRoot
    Assert-Package $p netfx-Guard
    Assert-SolutionPackage netfx-Guard
    Assert-NotNull (Get-ProjectItem $p App_Code\netfx\System\Guard.cs)
    
    # Assert
    $p | Uninstall-Package netfx-Guard
    Assert-Null (Get-ProjectPackage $p netfx-Guard)
    Assert-Null (Get-SolutionPackage netfx-Guard)
    Assert-Null (Get-ProjectItem $p App_Code\netfx\System\Guard.cs)
    Assert-Null (Get-ProjectItem $p App_Code\netfx\System)
    Assert-Null (Get-ProjectItem $p App_Code\netfx)
    Assert-Null (Get-ProjectItem $p App_Code)
}

function Test-WebSiteUninstallWithNestedAspxPPFiles {
    param(
        $context
    )

    # Arrange
    $p = New-WebSite    
    $files = @('About.aspx')
    $p | Install-Package PackageWithNestedAspxPPFiles -Source $context.RepositoryRoot

    $files | %{ 
        $item = Get-ProjectItem $p $_
        Assert-NotNull $item
        $codeItem = Get-ProjectItem $p "$_.cs"
        Assert-NotNull $codeItem
    }

    Assert-Package $p PackageWithNestedAspxPPFiles 1.0
    Assert-SolutionPackage PackageWithNestedAspxPPFiles 1.0

    # Act
    $p | Uninstall-Package PackageWithNestedAspxPPFiles

    # Assert
    $files | %{ 
        $item = Get-ProjectItem $p $_
        Assert-Null $item
        $codeItem = Get-ProjectItem $p "$_.cs"
        Assert-Null $codeItem
    }

    Assert-Null (Get-ProjectPackage $p PackageWithNestedAspxPPFiles 1.0)
    Assert-Null (Get-SolutionPackage PackageWithNestedAspxPPFiles 1.0)
}

function Test-WebsiteUninstallPackageWithNestedAspxFiles {
    param(
        $context
    )

    # Arrange
    $p = New-WebSite    
    $files = @('Global.asax', 'Site.master', 'About.aspx')
    $p | Install-Package PackageWithNestedAspxFiles -Source $context.RepositoryRoot

    $files | %{ 
        $item = Get-ProjectItem $p $_
        Assert-NotNull $item
        $codeItem = Get-ProjectItem $p "$_.cs"
        Assert-NotNull $codeItem
    }

    Assert-Package $p PackageWithNestedAspxFiles 1.0
    Assert-SolutionPackage PackageWithNestedAspxFiles 1.0

    # Act
    $p | Uninstall-Package PackageWithNestedAspxFiles

    # Assert
    $files | %{ 
        $item = Get-ProjectItem $p $_
        Assert-Null $item
        $codeItem = Get-ProjectItem $p "$_.cs"
        Assert-Null $codeItem
    }
    Assert-Null (Get-ProjectPackage $p PackageWithNestedAspxFiles 1.0)
    Assert-Null (Get-SolutionPackage PackageWithNestedAspxFiles 1.0)
}

function Test-WebSiteUninstallPackageWithNestedSourceFilesAndAnotherProject {
    param(
        $context
    )
    # Arrange
    $p1 = New-WebSite
    $p2 = New-WebApplication
    
    # Act
    $p1 | Install-Package netfx-Guard -Source $context.RepositoryRoot
    Assert-Package $p1 netfx-Guard
    Assert-SolutionPackage netfx-Guard
    Assert-NotNull (Get-ProjectItem $p1 App_Code\netfx\System\Guard.cs)

    $p2 | Install-Package netfx-Guard -Source $context.RepositoryRoot
    Assert-Package $p2 netfx-Guard
    Assert-SolutionPackage netfx-Guard
    Assert-NotNull (Get-ProjectItem $p2 netfx\System\Guard.cs)
    
    # Assert
    $p1 | Uninstall-Package netfx-Guard
    Assert-NotNull (Get-SolutionPackage netfx-Guard)
    Assert-Null (Get-ProjectPackage $p1 netfx-Guard)
    Assert-Null (Get-ProjectItem $p1 App_Code\netfx\System\Guard.cs)
    Assert-Null (Get-ProjectItem $p1 App_Code\netfx\System)
    Assert-Null (Get-ProjectItem $p1 App_Code\netfx)
    Assert-Null (Get-ProjectItem $p1 App_Code)
}

function Test-UninstallPackageSwallowExceptionThrownByUninstallScript {
   param(
       $context
   )

   # Arrange
   $p = New-ConsoleApplication
   $p | Install-Package TestUninstallThrowPackage -Source $context.RepositoryRoot
   Assert-Package $p TestUninstallThrowPackage

   # Act
   $p | Uninstall-Package TestUninstallThrowPackage

   # Assert
   Assert-Null (Get-ProjectPackage $p TestUninstallThrowPackage)

}

function Test-UninstallPackageInvokeInstallScriptWhenProjectNameHasApostrophe {
    param(
        $context
    )
    
    # Arrange
    New-Solution "Gun 'n Roses"
    $p = New-ConsoleApplication

    Install-Package TestUpdatePackage -Version 1.0.0.0 -Source $context.RepositoryRoot

    $global:UninstallPackageMessages = @()

    $expectedMessage = "uninstall" + $p.Name

    # Act
    Uninstall-Package TestUpdatePackage -Version 1.0.0.0

    # Assert
    Assert-AreEqual 1 $global:UninstallPackageMessages.Count
    Assert-AreEqual $expectedMessage $global:UninstallPackageMessages[0]

    # Clean up
    Remove-Variable UninstallPackageMessages -Scope Global
}

function Test-UninstallPackageInvokeInstallScriptWhenProjectNameHasBrackets {
    param(
        $context
    )
    
    # Arrange
    New-Solution "Gun [] Roses 2"
    $p = New-ConsoleApplication

    Install-Package TestUpdatePackage -Version 1.0.0.0 -Source $context.RepositoryRoot

    $global:UninstallPackageMessages = @()

    $expectedMessage = "uninstall" + $p.Name

    # Act
    Uninstall-Package TestUpdatePackage -Version 1.0.0.0

    # Assert
    Assert-AreEqual 1 $global:UninstallPackageMessages.Count
    Assert-AreEqual $expectedMessage $global:UninstallPackageMessages[0]

    # Clean up
    Remove-Variable UninstallPackageMessages -Scope Global
}

function Test-UninstallPackageRemoveSolutionPackagesConfig
{
    param(
        $context
    )

    # Arrange
    $a = New-ClassLibrary

    $a | Install-Package SolutionOnlyPackage -version 1.0 -source $context.RepositoryRoot
    
    $solutionFile = Get-SolutionPath
    $solutionDir = Split-Path $solutionFile -Parent

    $configFile = "$solutionDir\.nuget\packages.config"
    
    Assert-True (Test-Path $configFile)

    $content = Get-Content $configFile
    Assert-AreEqual 4 $content.Length
    Assert-AreEqual '<?xml version="1.0" encoding="utf-8"?>' $content[0]
    Assert-AreEqual '<packages>' $content[1]
    Assert-AreEqual '  <package id="SolutionOnlyPackage" version="1.0" />' $content[2]
    Assert-AreEqual '</packages>' $content[3]

    # Act
    $a | Uninstall-Package SolutionOnlyPackage

    # Assert
    Assert-False (Test-Path $configFile)
}

function Test-UninstallPackageRemoveEntryFromSolutionPackagesConfig
{
    param(
        $context
    )

    # Arrange
    $a = New-ClassLibrary

    $a | Install-Package SolutionLevelPkg -version 1.0.0 -source $context.RepositoryRoot
    $a | Install-Package RazorGenerator.MsBuild -version 1.3.2
    
    $solutionFile = Get-SolutionPath
    $solutionDir = Split-Path $solutionFile -Parent

    $configFile = "$solutionDir\.nuget\packages.config"
    
    Assert-True (Test-Path $configFile)

    $content = Get-Content $configFile
    Assert-AreEqual 5 $content.Length
    Assert-AreEqual '<?xml version="1.0" encoding="utf-8"?>' $content[0]
    Assert-AreEqual '<packages>' $content[1]
    Assert-AreEqual '  <package id="RazorGenerator.MsBuild" version="1.3.2.0" />' $content[2]
    Assert-AreEqual '  <package id="SolutionLevelPkg" version="1.0.0" />' $content[3]
    Assert-AreEqual '</packages>' $content[4]

    # Act
    $a | Uninstall-Package RazorGenerator.MsBuild

    # Assert
    $content = Get-Content $configFile
    Assert-AreEqual 4 $content.Length
    Assert-AreEqual '<?xml version="1.0" encoding="utf-8"?>' $content[0]
    Assert-AreEqual '<packages>' $content[1]
    Assert-AreEqual '  <package id="SolutionLevelPkg" version="1.0.0" />' $content[2]
    Assert-AreEqual '</packages>' $content[3]
}

function Test-UninstallingSatellitePackageRemovesFilesFromRuntimePackageFolder
{
    param(
        $context
    )

    # Arrange
    $p = New-ClassLibrary
    $solutionDir = Get-SolutionDir

    # Act
    $p | Install-Package PackageWithStrongNamedLib -Source $context.RepositoryPath
    $p | Install-Package PackageWithStrongNamedLib.ja-jp -Source $context.RepositoryPath

    $p | Uninstall-Package PackageWithStrongNamedLib.ja-jp

    # Assert (the resources from the satellite package are copied into the runtime package's folder)
    Assert-PathNotExists (Join-Path $solutionDir packages\PackageWithStrongNamedLib.1.1\lib\ja-jp\Core.resources.dll)
    Assert-PathNotExists (Join-Path $solutionDir packages\PackageWithStrongNamedLib.1.1\lib\ja-jp\Core.xml)
}

function Test-UninstallingSatellitePackageDoesNotRemoveCollidingRuntimeFilesWhenContentsDiffer
{
    param(
        $context
    )

    # Arrange
    $p = New-ClassLibrary
    $solutionDir = Get-SolutionDir

    # Act
    $p | Install-Package PackageWithStrongNamedLib -Source $context.RepositoryPath
    $p | Install-Package PackageWithStrongNamedLib.ja-jp -Source $context.RepositoryPath

    $p | Uninstall-Package PackageWithStrongNamedLib.ja-jp 

    # Assert (the resources from the satellite package are copied into the runtime package's folder)
    Assert-PathExists (Join-Path $solutionDir packages\PackageWithStrongNamedLib.1.1\lib\ja-jp\collision-differences.txt)
}

function Test-UninstallingSatellitePackageDoesRemoveCollidingRuntimeFilesWhenContentsMatch
{
    param(
        $context
    )

    # Arrange
    $p = New-ClassLibrary
    $solutionDir = Get-SolutionDir

    # Act
    $p | Install-Package PackageWithStrongNamedLib -Source $context.RepositoryPath
    $p | Install-Package PackageWithStrongNamedLib.ja-jp -Source $context.RepositoryPath

    $p | Uninstall-Package PackageWithStrongNamedLib.ja-jp

    # Assert (the resources from the satellite package are copied into the runtime package's folder)
    Assert-PathNotExists (Join-Path $solutionDir packages\PackageWithStrongNamedLib.1.1\lib\ja-jp\collision-match.txt)
}

function Test-UninstallingSatellitePackageThenRuntimePackageRemoveCollidingRuntimeFilesWhenContentsDiffer
{
    param(
        $context
    )

    # Arrange
    $p = New-ClassLibrary
    $solutionDir = Get-SolutionDir

    # Act
    $p | Install-Package PackageWithStrongNamedLib -Source $context.RepositoryPath
    $p | Install-Package PackageWithStrongNamedLib.ja-jp -Source $context.RepositoryPath

    $p | Uninstall-Package PackageWithStrongNamedLib.ja-jp
    $p | Uninstall-Package PackageWithStrongNamedLib

    # Assert (the resources from the satellite package are copied into the runtime package's folder)
    Assert-PathNotExists (Join-Path $solutionDir packages\PackageWithStrongNamedLib.1.1\lib\ja-jp\collision-differences.txt)
}

function Test-WebSiteSimpleUninstall
{
    param(
        $context
    )

    # Arrange
    $p = New-Website
    
    # Act
    $p | Install-Package MyAwesomeLibrary -Source $context.RepositoryPath
    $p | Uninstall-Package MyAwesomeLibrary

    # Assert
    Assert-PathNotExists (Join-Path (Get-ProjectDir $p) "bin\AwesomeLibrary.dll.refresh")
}

function Test-UninstallPackageUseTheTargetFrameworkPersistedInPackagesConfigToRemoveContentFiles
{
    param($context)

    # Arrange
    $p = New-ClassLibrary

    $p | Install-Package PackageA -Source $context.RepositoryPath
    
    Assert-Package $p 'packageA'
    Assert-Package $p 'packageB'

    Assert-NotNull (Get-ProjectItem $p testA4.txt)
    Assert-NotNull (Get-ProjectItem $p testB4.txt)

    # Act (change the target framework of the project to 3.5 and verifies that it still removes the content files correctly )

    $projectName = $p.Name
    $p.Properties.Item("TargetFrameworkMoniker").Value = '.NETFramework,Version=3.5'

    $p = Get-Project $projectName

    Uninstall-Package 'PackageA' -Project $projectName -RemoveDependencies
    
    # Assert
    Assert-NoPackage $p 'PackageA'
    Assert-NoPackage $p 'PackageB'
    
    Assert-Null (Get-ProjectItem $p testA4.txt)
    Assert-Null (Get-ProjectItem $p testB4.txt)
}

function Test-UninstallPackageUseTheTargetFrameworkPersistedInPackagesConfigToRemoveAssemblyReferences
{
    param($context)

    # Arrange
    $p = New-ClassLibrary

    $p | Install-Package PackageA -Source $context.RepositoryPath
    
    Assert-Package $p 'packageA'
    Assert-Package $p 'packageB'

    Assert-Reference $p testA4
    Assert-Reference $p testB4

    # Act (change the target framework of the project to 3.5 and verifies that it still removes the assembly references correctly )

    $projectName = $p.Name
    $p.Properties.Item("TargetFrameworkMoniker").Value = '.NETFramework,Version=3.5'

    $p = Get-Project $projectName

    Uninstall-Package 'PackageA' -Project $projectName -RemoveDependencies
    
    # Assert
    Assert-NoPackage $p 'PackageA'
    Assert-NoPackage $p 'PackageB'
    
    Assert-Null (Get-AssemblyReference $p testA4.dll)
    Assert-Null (Get-AssemblyReference $p testB4.dll)
}

function Test-UninstallPackageUseTheTargetFrameworkPersistedInPackagesConfigToInvokeUninstallScript
{
    param($context)

    # Arrange
    $p = New-ClassLibrary

    $p | Install-Package PackageA -Source $context.RepositoryPath
    
    Assert-Package $p 'packageA'

    # Act (change the target framework of the project to 3.5 and verifies that it invokes the correct uninstall.ps1 file in 'net40' folder )

    $projectName = $p.Name
    $p.Properties.Item("TargetFrameworkMoniker").Value = '.NETFramework,Version=3.5'

    $global:UninstallVar = 0

    $p = Get-Project $projectName
    Uninstall-Package 'PackageA' -Project $projectName
    
    # Assert
    Assert-NoPackage $p 'PackageA'
    
    Assert-AreEqual 1 $global:UninstallVar

    Remove-Variable UninstallVar -Scope Global
}


function Test-ToolsPathForUninstallScriptPointToToolsFolder
{
    param($context)

    # Arrange
    $p = New-SilverlightApplication

    $p | Install-Package PackageA -Version 1.0.0 -Source $context.RepositoryPath
    Assert-Package $p 'packageA'

    # Act

    $p | Uninstall-Package PackageA
}

function Test-FinishFailedUninstallOnSolutionOpen
{
    param($context)

    # Arrange
    $p = New-ConsoleApplication

    $packageManager = $host.PrivateData.packageManagerFactory.CreatePackageManager()
    $localRepositoryPath = $packageManager.LocalRepository.Source
    $physicalFileSystem = New-Object NuGet.PhysicalFileSystem($localRepositoryPath)

    $p | Install-Package SolutionLevelPkg -Version 1.0.0 -Source $context.RepositoryRoot

    # We will open a file handle preventing the deletion packages\SolutionLevelPkg.1.0.0\tools\Sample.targets
    # causing the uninstall to fail to complete thereby forcing it to finish the next time the solution is opened
    $filePath = Join-Path $localRepositoryPath "SolutionLevelPkg.1.0.0\tools\Sample.targets"
    $fileStream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)

    try {
        # Act
        $p | Uninstall-Package SolutionLevelPkg

        # Assert
        Assert-True $physicalFileSystem.DirectoryExists("SolutionLevelPkg.1.0.0")
        Assert-True $physicalFileSystem.FileExists("SolutionLevelPkg.1.0.0.deleteme")

    } finally {
        $fileStream.Close()
    }

    # Act
    # After closing the file handle, we close the solution and reopen it
    $solutionDir = $dte.Solution.FullName
    Close-Solution
    Open-Solution $solutionDir

    # Assert
    Assert-False $physicalFileSystem.DirectoryExists("SolutionLevelPkg.1.0.0")
    Assert-False $physicalFileSystem.FileExists("SolutionLevelPkg.1.0.0.deleteme")
}

function Test-FinishFailedUninstallOnSolutionOpenOfProjectLevelPackage
{
    param($context)

    # Arrange
    $p = New-ConsoleApplication

    $packageManager = $host.PrivateData.packageManagerFactory.CreatePackageManager()
    $localRepositoryPath = $packageManager.LocalRepository.Source
    $physicalFileSystem = New-Object NuGet.PhysicalFileSystem($localRepositoryPath)

    $p | Install-Package PackageWithTextFile -Version 1.0 -Source $context.RepositoryRoot

    # We will open a file handle preventing the deletion packages\PackageWithTextFile.1.0\content\text
    # causing the uninstall to fail to complete thereby forcing it to finish the next time the solution is opened
    $filePath = Join-Path $localRepositoryPath "PackageWithTextFile.1.0\content\text"
    $fileStream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)

    try {
        # Act
        $p | Uninstall-Package PackageWithTextFile

        # Assert
        Assert-True $physicalFileSystem.DirectoryExists("PackageWithTextFile.1.0")
        Assert-True $physicalFileSystem.FileExists("PackageWithTextFile.1.0.deleteme")

    } finally {
        $fileStream.Close()
    }

    # Act
    # After closing the file handle, we close the solution and reopen it
    $solutionDir = $dte.Solution.FullName
    Close-Solution
    Open-Solution $solutionDir

    # Assert
    Assert-False $physicalFileSystem.DirectoryExists("PackageWithTextFile.1.0")
    Assert-False $physicalFileSystem.FileExists("PackageWithTextFile.1.0.deleteme")
}


function Test-UnInstallPackageWithXdtTransformUnTransformsTheFile
{
    # Arrange
    $p = New-WebApplication

    # Act
    $p | Install-Package XdtPackage -Source $context.RepositoryPath

    # Assert
    Assert-Package $p 'XdtPackage' '1.0.0'

    $content = [xml](Get-Content (Get-ProjectItemPath $p web.config))

    Assert-AreEqual "false" $content.configuration["system.web"].compilation.debug
    Assert-NotNull $content.configuration["system.web"].customErrors

    # Act 2
    $p | UnInstall-Package XdtPackage

    # Assert 2
    Assert-NoPackage $p 'XdtPackage' '1.0.0'

    $content = [xml](Get-Content (Get-ProjectItemPath $p web.config))

    Assert-AreEqual "true" $content.configuration["system.web"].compilation.debug
    Assert-Null $content.configuration["system.web"].customErrors
}
function Test-UninstallPackageUninstallAssemblyReferencesHonoringPackageReferencesAccordingToProjectFramework
{
    # Arrange
    $p = New-ClassLibrary

    $p | Install-Package mars -Source $repositoryPath
    $p | Install-Package natal -Source $repositoryPath

    Assert-Package $p mars
    Assert-Package $p natal

    # Act
    $p | Uninstall-Package natal

    # Assert
    Assert-Reference $p one
    Assert-Null (Get-AssemblyReference $p two)
    Assert-Null (Get-AssemblyReference $p three)
}