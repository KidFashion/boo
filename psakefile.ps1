Properties {
    $script:hash = @{}
    $script:hash.build_mode = "Release"
    $solution = (ls *.sln).Name
    $packageName = [System.IO.Path]::GetFileNameWithoutExtension((ls *.sln))
    # Test
    $testPrj = "..\..\tests\"

    $booc = $null
    # Directories
    # Directory of output binaries (output of Visual Studio)
    $outdir = if (test-path env:CCNetArtifactDirectory) {[System.String]::Concat((ls env:CCNetArtifactDirectory).Value,"\Staging\\")} else {[System.String]::Concat((pwd),"\Staging\\")}
    $artifactdir = [System.String]::Concat((pwd),"\Artifacts\")
    $deployPackageDir = (join-path $outdir "..\DeployPackage")
}

Task default -depends Print-TaskList 

Task setConfiguration-Debug {
$script:hash.build_mode = "Debug"
}

Task setConfiguration-Release {
$script:hash.build_mode = "Release"
}

Task Print-Banner {
Write-Host -ForegroundColor Yellow "============================================="
Write-Host -ForegroundColor Yellow "Project: Boo Language"
Write-Host -ForegroundColor Yellow "Description of Boo Language"
Write-Host -ForegroundColor Yellow "Author: Angelo Simone Scotto"
Write-Host -ForegroundColor Yellow "Url: https://github.com/KidFashion/boo"
Write-Host -ForegroundColor Yellow "============================================="

}

Task Print-TaskList -depends Print-Banner {
Write-Host -ForegroundColor White "List of Available Tasks:"
Write-Host -ForegroundColor Green "Print-TaskList" -nonewline;Write-Host " : Print these instructions."
Write-Host -ForegroundColor Green "Build-BooCore"-nonewline; write-host " : Build Boo.Lang, Boo.Lang.Compiler and Boo.Lang.Parser (NET48)"
Write-Host -ForegroundColor Green "Build-BooCompilerTool"-nonewline; write-host " : Build (Booc) Boo.Lang, Boo.Lang.Compiler and Boo.Lang.Parser (NET48)"
Write-Host -ForegroundColor Green "Build-Booi"-nonewline; write-host " : Build (Booi) Boo Interpreter (NET48)"
Write-Host -ForegroundColor Green "Build-Booish"-nonewline; write-host " : Build (Booish) Boo Interpreter Shell (NET48)"
Write-Host -ForegroundColor Green "Clean-All"-nonewline; write-host " : Clean Artifacts folder."
#Write-Host -ForegroundColor Green "Build-Solution-net40"-nonewline; write-host " : Build Project (4.0)"

}

Task Build-BooLang {
    Push-Location src/Boo.Lang
    dotnet build Boo.Lang.csproj
    pop-location
}

Task Build-BooLangCompiler {
    Push-Location src/Boo.Lang.Compiler
    dotnet build Boo.Lang.Compiler.csproj
    pop-location
}

Task Build-BooLangParser {
    Push-Location src/Boo.Lang.Parser
    dotnet build Boo.Lang.Parser.csproj
    pop-location
}

Task Build-BooCompilerTool -depends Build-BooLangCompiler, Build-BooLang{
    Push-Location src/Booc
    dotnet build Booc.csproj
    # TODO: Check Release/Debug/Framework
    $buildOutput = join-path (Get-Location) "bin\Debug\net48\"
    Copy-Item (join-path $buildOutput "*.*") $artifactdir
    pop-location
    $script:booc = join-path ($artifactdir) "\booc.exe"
}

Task Build-BooCore -depends Build-BooLang, Build-BooLangCompiler, Build-BooLangParser{
}

Task Clean-All {
    Remove-Item -Force -Recurse $artifactdir
}

Task Init-All {
    mkdir -Force $artifactdir
}
Task Build-BooLangExtensions -depends Init-All, Build-BooCompilerTool {
    Push-Location src/Boo.Lang.Extensions
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.Extensions.dll" `
        .\AssemblyInfo.boo `
        .\Macros\AssertMacro.boo `
        .\Macros\CheckedMacro.boo `
        .\Macros\DebugMacro.boo `
        .\Macros\Globals.boo `
        .\Macros\IfdefMacro.boo `
        .\Macros\Initialization.boo `
        .\Macros\LockMacro.boo `
        .\Macros\PreservingMacro.boo `
        .\Macros\PrintMacro.boo `
        .\Macros\PropertyMacro.boo `
        .\Macros\RawArrayIndexingMacro.boo `
        .\Macros\UnsafeMacro.boo `
        .\Macros\UsingMacro.boo `
        .\Macros\VarMacro.boo `
        .\Macros\YieldAllMacro.boo `
        .\MetaMethods\Async.boo `
        .\MetaMethods\Await.boo `
        .\MetaMethods\DefaultMetaMethod.boo `
        .\MetaMethods\SizeOf.boo `
        .\Environments\EnvironmentExtensions.boo `
        .\Attributes\AsyncAttribute.boo `
        .\Attributes\DefaultAttribute.boo `
        .\Attributes\GetterAttribute.boo `
        .\Attributes\LockAttribute.boo `
        .\Attributes\PropertyAttribute.boo `
        .\Attributes\RequiredAttribute.boo `
        .\Attributes\TransientAttribute.boo `
        .\Attributes\VolatileAttribute.boo 
    pop-location
}

Task Build-BooLangPatternMatching -depends Init-All, Build-BooCompilerTool {
    Push-Location src/Boo.Lang.PatternMatching
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.PatternMatching.dll" `
        -srcdir:.
    pop-location
}


Task Build-TestBooSupportingClasses -depends Init-All, Build-BooCompilerTool {
    Push-Location tests/BooSupportingClasses
    &$script:booc `
        -o:"$artifactdir\BooSupportingClasses.dll" `
        -srcdir:.
    pop-location
}

Task Build-TestBooModules -depends Init-All, Build-BooCompilerTool {
    Push-Location tests/BooModules
    &$script:booc `
        -o:"$artifactdir\BooModules.dll" `
        -srcdir:.
    pop-location
}

Task Build-BooLangInterpreter -depends Init-All, Build-BooCompilerTool, Build-BooLangPatternMatching {
    Push-Location src/Boo.Lang.Interpreter
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.Interpreter.dll" `
        -srcdir:. `
        -r:"$artifactdir\Boo.Lang.PatternMatching.dll"
    pop-location
}

Task Build-BooLangUseful -depends Init-All, Build-BooCompilerTool {
    Push-Location src/Boo.Lang.Useful
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.Useful.dll" `
        -srcdir:. `
        -r:../Boo.Lang.Parser/bin/Debug/net48/Boo.Lang.Parser.dll
    pop-location
}


Task Build-Booi -depends Init-All, Build-BooCompilerTool, Build-BooLangUseful {
    Push-Location src/Booi
    &$script:booc `
        -o:"$artifactdir\booi.exe" `
        -srcdir:. `
        -r:../Boo.Lang.Useful/Boo.Lang.Useful.dll
    pop-location
}

Task Build-Booish -depends Init-All, Build-BooCompilerTool, Build-BooLangInterpreter {
    Push-Location src/Booish
    &$script:booc `
        -o:"$artifactdir\booish.exe" `
        -r:../Boo.Lang.Interpreter/Boo.Lang.Interpreter.dll `
        booish.boo
    pop-location
}

Task Build-BooLangCodeDom -depends Init-All,Build-BooCompilerTool {
    Push-Location src/Boo.Lang.CodeDom
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.CodeDom.dll" `
        -srcdir:.
    pop-location
}


Task Build-BooCompilerResourcesTests -depends Init-All, Build-BooCompilerTool {
    Push-Location tests/BooCompilerResources.Tests
    $nunit_ref = Get-NUnitPackageLocation .\BooCompilerResources.Tests.build
    Write-Host $nunit_ref
    &$script:booc `
        -o:"$artifactdir\BooCompilerResources.Tests.dll" `
        -srcdir:. `
        -r:$nunit_ref
    pop-location

}

Task Build-BooLangCodedomTests -depends Init-All, Build-BooLangCodedom, Build-BooCompilerTool {
    Push-Location tests/Boo.Lang.CodeDom.Tests
    $nunit_ref = Get-NUnitPackageLocation .\Boo.Lang.CodeDom.Tests.build
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.CodeDom.Tests.dll" `
        -srcdir:. `
        -r:$nunit_ref 
    pop-location
}

Task Build-BooLangCompilerTests -depends Init-All, Build-BooLangCompiler, Build-BooCompilerTool {
    Push-Location tests/Boo.Lang.Compiler.Tests
    $nunit_ref = Get-NUnitPackageLocation .\Boo.Lang.Compiler.Tests.build
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.Compiler.Tests.dll" `
        -srcdir:. `
        -r:$nunit_ref 
    pop-location
}

Task Build-BooLangInterpreterTests -depends Init-All, Build-BooLangInterpreter, Build-BooCompilerTool {
    Push-Location tests/Boo.Lang.Interpreter.Tests
    $nunit_ref = Get-NUnitPackageLocation .\Boo.Lang.Interpreter.Tests.build
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.Interpreter.Tests.dll" `
        -srcdir:. `
        -r:$nunit_ref `
        -r:"$artifactdir\Boo.Lang.Interpreter.dll" 
    pop-location
}

Task Build-BooLangPatternMatchingTests -depends Init-All, Build-BooLangPatternMatching, Build-BooCompilerTool {
    Push-Location tests/Boo.Lang.PatternMatching.Tests
    $nunit_ref = Get-NUnitPackageLocation .\Boo.Lang.PatternMatching.Tests.build
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.PatternMatching.Tests.dll" `
        -srcdir:. `
        -r:$nunit_ref `
        -r:"$artifactdir\Boo.Lang.PatternMatching.dll" 
    pop-location
}

Task Build-BooLangUsefulTests -depends Init-All, Build-BooLangUseful, Build-BooCompilerTool {
    Push-Location tests/Boo.Lang.Useful.Tests
    $nunit_ref = Get-NUnitPackageLocation .\Boo.Lang.Useful.Tests.build
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.Useful.Tests.dll" `
        -srcdir:. `
        -r:$nunit_ref `
        -r:"$artifactdir\Boo.Lang.Useful.dll" 
    pop-location
}

# Depends on building all boo tests and installing nunit3-console and referencing nunit.* dlls
Task Test-BooCompiledAssemblies -depends Init-All {
    Push-Location ./Artifacts
    nunit3-console `
        Boo.Lang.CodeDom.Tests.dll `
        Boo.Lang.Compiler.Tests.dll `
        Boo.Lang.Interpreter.Tests.dll `
        Boo.Lang.PatternMatching.Tests.dll `
        Boo.Lang.Useful.Tests.dll `
        BooCompilerResources.Tests.dll

    $xml = [xml](Get-Content .\TestResult.xml)
    $xml.'test-run'.'test-suite' | ForEach-Object {
        if ($_.result -eq "Passed") {$color = [System.ConsoleColor]::Green}
        else {$color = [System.ConsoleColor]::Red}
        Write-Host -ForegroundColor Yellow "Name: $($_.name)"
        Write-Host -ForegroundColor $color "Result: $($_.result) Total Tests: $($_.total) Passed: $($_.passed) Failed: $($_.failed) Warnings: $($_.warnings) Inconclusive: $($_.inconclusive) Skipped: $($_.skipped)"
    }
    Pop-Location
}

######################### HELPER FUNCTIONS ##########################################
    # Default target version right now is NET Framework 4.8, when converted booc to msbuild task this would not be needed anymore (hopefully)
    function Get-NUnitPackageLocation ($msbuild_file) {
    $default_target = "4\.8"
    dotnet restore $msbuild_file | out-null
    $assetObject = Get-Content .\obj\project.assets.json | convertfrom-json
    
    $libraries = Get-ValueFromJSON $assetObject.targets $default_target
    $nunit = Get-ValueFromJSON $libraries[1] "NUnit/"
    $nunit_location = $nunit[1].compile | get-Member |where MemberType -eq "NoteProperty"|select Name
    $base_packagelocation = $assetObject.packageFolders | get-Member |where MemberType -eq "NoteProperty"|select Name
    Return Join-Path (Join-Path $base_packagelocation.Name $nunit[0]) $nunit_location.Name
}


function Get-ValueFromJSON ($json, $partial_key)
{
    $fieldName = ($json |Get-Member | Where-object Name -match $partial_key).Name
    $fieldValue = $json.$fieldName
    return $fieldName, $fieldValue
}