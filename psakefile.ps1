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
    # HACK: Hardwired target and release type (Debug)
    $buildOutput = "bin/Debug/net48"
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

Task Build-BooLang -depends Init-All {
    Push-Location src/Boo.Lang
    dotnet build Boo.Lang.csproj
    Copy-Item (join-path $buildOutput "*.*") $artifactdir
    pop-location
}

Task Build-BooLangCompiler -depends Init-All {
    Push-Location src/Boo.Lang.Compiler
    dotnet build Boo.Lang.Compiler.csproj
    Copy-Item (join-path $buildOutput "*.*") $artifactdir
    pop-location
}

Task Build-BooLangParser -depends Init-All {
    Push-Location src/Boo.Lang.Parser
    dotnet build Boo.Lang.Parser.csproj
    Copy-Item (join-path $buildOutput "*.*") $artifactdir
    pop-location
}

Task Build-BooCompilerTool -depends Build-BooLangCompiler, Build-BooLang, Init-All{
    Push-Location src/Booc
    dotnet build Booc.csproj
    # TODO: Check Release/Debug/Framework
    Copy-Item (join-path $buildOutput "*.*") $artifactdir
    pop-location
    $script:booc = join-path ($artifactdir) "\booc.exe"
}

Task Build-BooCore -depends Build-BooLang, Build-BooLangCompiler, Build-BooLangParser{
}

Task Build-All -depends Build-BooLangCodeDom,
                        Build-BooLangExtensions,
                        Build-BooLangPatternMatching,
                        Build-Booish,
                        Build-Booi,
                        Build-BooLangInterpreter,
                        Build-BooLangUseful,
                        Build-BooLangParser,
                        Build-BooLangCompiler,
                        Build-BooLang {
}

Task Clean-All {
    Remove-Item -Force -Recurse $artifactdir
}

Task Init-All {
    mkdir -Force $artifactdir
}
Task Build-BooLangExtensions -depends Build-BooCompilerTool, Init-All {
    Push-Location src/Boo.Lang.Extensions
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.Extensions.dll" `
        -r:"$artifactdir\Boo.Lang.Parser.dll" `
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
        Move-Item -Force ./Boo.Lang.Extensions.dll "$artifactdir\Boo.Lang.Extensions.dll" 
        Move-Item -Force ./Boo.Lang.Extensions.pdb "$artifactdir\Boo.Lang.Extensions.pdb" 

    pop-location
}

Task Build-BooLangPatternMatching -depends Build-BooCompilerTool, Init-All {
    Push-Location src/Boo.Lang.PatternMatching
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.PatternMatching.dll" `
        -srcdir:.
    pop-location
}


Task Build-TestBooSupportingClasses -depends Build-BooCompilerTool, Init-All {
    Push-Location tests/BooSupportingClasses
    &$script:booc `
        -o:"$artifactdir\BooSupportingClasses.dll" `
        -srcdir:.
    pop-location
}

Task Build-TestBooModules -depends Build-BooCompilerTool, Init-All {
    Push-Location tests/BooModules
    &$script:booc `
        -o:"$artifactdir\BooModules.dll" `
        -srcdir:.
    pop-location
}

Task Build-BooLangInterpreter -depends Build-BooCompilerTool, Build-BooLangPatternMatching, Init-All {
    Push-Location src/Boo.Lang.Interpreter
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.Interpreter.dll" `
        -srcdir:. `
        -r:"$artifactdir\Boo.Lang.PatternMatching.dll"
    pop-location
}

Task Build-BooLangUseful -depends Build-BooCompilerTool, Init-All {
    Push-Location src/Boo.Lang.Useful
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.Useful.dll" `
        -srcdir:. `
        -r:"$artifactdir\Boo.Lang.Parser.dll"
    pop-location
}


Task Build-Booi -depends Build-BooCompilerTool, Build-BooLangUseful, Init-All {
    Push-Location src/Booi
    &$script:booc `
        -o:"$artifactdir\booi.exe" `
        -srcdir:. `
        -r:"$artifactdir/Boo.Lang.Useful.dll"
    pop-location
}

Task Build-Booish -depends Build-BooCompilerTool, Build-BooLangInterpreter, Init-All {
    Push-Location src/Booish
    &$script:booc `
        -o:"$artifactdir\booish.exe" `
        -r:"$artifactdir\Boo.Lang.Interpreter.dll" `
        booish.boo
    pop-location
}

Task Build-BooLangCodeDom -depends Build-BooCompilerTool, Init-All {
    Push-Location src/Boo.Lang.CodeDom
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.CodeDom.dll" `
        -srcdir:.
        -r:"$artifactdir\Boo.Lang.Parser.dll" `
    pop-location
}


Task Build-BooCompilerResourcesTests -depends Build-BooCompilerTool, Init-All {
    Push-Location tests/BooCompilerResources.Tests
    $nunit_ref = Get-NUnitPackageLocation .\BooCompilerResources.Tests.build
    Write-Host $nunit_ref
    &$script:booc `
        -o:"$artifactdir\BooCompilerResources.Tests.dll" `
        -srcdir:. `
        -r:$nunit_ref
    pop-location

}

Task Build-BooLangCodedomTests -depends  Build-BooLangCodedom, Build-BooCompilerTool, Init-All {
    Push-Location tests/Boo.Lang.CodeDom.Tests
    $nunit_ref = Get-NUnitPackageLocation .\Boo.Lang.CodeDom.Tests.build
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.CodeDom.Tests.dll" `
        -srcdir:. `
        -r:$nunit_ref 
    pop-location
}

Task Build-BooLangCompilerTests -depends Build-BooLangCompiler, Build-BooCompilerTool, Init-All {
    Push-Location tests/Boo.Lang.Compiler.Tests
    $nunit_ref = Get-NUnitPackageLocation .\Boo.Lang.Compiler.Tests.build
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.Compiler.Tests.dll" `
        -srcdir:. `
        -r:$nunit_ref 
    pop-location
}

Task Build-BooLangInterpreterTests -depends  Build-BooLangInterpreter, Build-BooCompilerTool, Init-All {
    Push-Location tests/Boo.Lang.Interpreter.Tests
    $nunit_ref = Get-NUnitPackageLocation .\Boo.Lang.Interpreter.Tests.build
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.Interpreter.Tests.dll" `
        -srcdir:. `
        -r:$nunit_ref `
        -r:"$artifactdir\Boo.Lang.Interpreter.dll" 
    pop-location
}

Task Build-BooLangPatternMatchingTests -depends Build-BooLangPatternMatching, Build-BooCompilerTool, Init-All {
    Push-Location tests/Boo.Lang.PatternMatching.Tests
    $nunit_ref = Get-NUnitPackageLocation .\Boo.Lang.PatternMatching.Tests.build
    &$script:booc `
        -o:"$artifactdir\Boo.Lang.PatternMatching.Tests.dll" `
        -srcdir:. `
        -r:$nunit_ref `
        -r:"$artifactdir\Boo.Lang.PatternMatching.dll" 
    pop-location
}

Task Build-BooLangTests -depends Build-BooLang {
    Push-Location tests/Boo.Lang.Tests
    dotnet build Boo.Lang.Tests.csproj
    # TODO: Check Release/Debug/Framework
    $buildOutput = join-path (Get-Location) "bin\Debug\net48\"
    Copy-Item (join-path $buildOutput "*.*") $artifactdir
    pop-location
}

Task Test-BooLang -depends Build-BooLangTests {
    Push-Location tests/Boo.Lang.Tests
    dotnet test Boo.Lang.Tests.csproj
    # TODO: Check Release/Debug/Framework
    pop-location
}

Task Build-BooLangParserTests -depends Build-BooLangParser {
    Push-Location tests/Boo.Lang.Parser.Tests
    dotnet build Boo.Lang.Parser.Tests.csproj
    # TODO: Check Release/Debug/Framework
    $buildOutput = join-path (Get-Location) "bin\Debug\net48\"
    Copy-Item (join-path $buildOutput "*.*") $artifactdir
    pop-location
}

Task Test-BooLangParser  {
    Push-Location tests/Boo.Lang.Parser.Tests
    dotnet test Boo.Lang.Parser.Tests.csproj
    # TODO: Check Release/Debug/Framework
    pop-location
}

Task Build-BooLangRuntimeTests {
    Push-Location tests/Boo.Lang.Runtime.Tests
    dotnet build Boo.Lang.Runtime.Tests.csproj
    # TODO: Check Release/Debug/Framework
    $buildOutput = join-path (Get-Location) "bin\Debug\net48\"
    Copy-Item (join-path $buildOutput "*.*") $artifactdir
    pop-location
}

Task Test-BooLangRuntime  {
    Push-Location tests/Boo.Lang.Runtime.Tests
    dotnet test Boo.Lang.Runtime.Tests.csproj
    # TODO: Check Release/Debug/Framework
    pop-location
}

Task Build-BoocTests {
    Push-Location tests/Booc.Tests
    dotnet build Booc.Tests.csproj
    # TODO: Check Release/Debug/Framework
    $buildOutput = join-path (Get-Location) "bin\Debug\net48\"
    Copy-Item (join-path $buildOutput "*.*") $artifactdir
    pop-location
}

Task Test-Booc  {
    Push-Location tests/Booc.Tests
    dotnet test Booc.Tests.csproj
    # TODO: Check Release/Debug/Framework
    pop-location
}

Task Build-BooCompilerTests {
    Push-Location tests/BooCompiler.Tests
    dotnet build BooCompiler.Tests.csproj
    # TODO: Check Release/Debug/Framework
    $buildOutput = join-path (Get-Location) "bin\Debug\net48\"
    Copy-Item (join-path $buildOutput "*.*") $artifactdir
    pop-location
}

Task Test-BooCompiler  {
    Push-Location tests/BooCompiler.Tests
    dotnet test BooCompiler.Tests.csproj
    # TODO: Check Release/Debug/Framework
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
# TODO: Boo compiled assemblies cannot be tested using dotnet test therefore nunit-console-runner must be installed (Via chocolatey) 
# TODO: and nunit*.dlls needs to be copied where nunit-console-runner can find them (i.e. artifacts)
Task Test-BooCompiledAssemblies -depends    Init-All, 
                                            Install-NUnitConsole, 
                                            Build-BooLangCodedomTests,
                                            Build-BooLangCompilerTests, 
                                            Build-BooLangInterpreterTests, 
                                            Build-BooLangPatternMatchingTests,
                                            Build-BooLangUsefulTests, 
                                            Build-BooCompilerResourcesTests {
    Push-Location ./Artifacts
    nunit3-console `
        Boo.Lang.CodeDom.Tests.dll `
        Boo.Lang.Compiler.Tests.dll `
        Boo.Lang.Interpreter.Tests.dll `
        Boo.Lang.PatternMatching.Tests.dll `
        Boo.Lang.Useful.Tests.dll `
        BooCompilerResources.Tests.dll
 
    Write-TestResults .\TestResult.xml
    Pop-Location
}

Task Test-CSharpCompiledAssemblies -depends Init-All, 
                                            Install-NUnitConsole, 
                                            Build-BooLangParserTests,
                                            Build-BooLangRuntimeTests, 
                                            Build-BooLangTests, 
                                            Build-BooCompilerTests, 
                                            Build-BoocTests {
    Push-Location ./Artifacts
    nunit3-console `
        Boo.Lang.Parser.Tests.dll `
        Boo.Lang.Runtime.Tests.dll `
        Boo.Lang.Tests.dll `
        BooCompiler.Tests.dll `
        Booc.Tests.dll

    Write-TestResults .\TestResult.xml
    Pop-Location
}


Task Test-All -depends  Init-All, 
                        Install-NUnitConsole, 
                        Build-BooLangParserTests,
                        Build-BooLangRuntimeTests, 
                        Build-BooLangTests, 
                        Build-BooCompilerTests, 
                        Build-BoocTests,
                        Build-BooLangCodedomTests,
                        Build-BooLangCompilerTests, 
                        Build-BooLangInterpreterTests, 
                        Build-BooLangPatternMatchingTests,
                        Build-BooLangUsefulTests, 
                        Build-BooCompilerResourcesTests {
    Push-Location ./Artifacts
    nunit3-console `
        Boo.Lang.Parser.Tests.dll `
        Boo.Lang.Runtime.Tests.dll `
        Boo.Lang.Tests.dll `
        BooCompiler.Tests.dll `
        Booc.Tests.dll `
        Boo.Lang.CodeDom.Tests.dll `
        Boo.Lang.Compiler.Tests.dll `
        Boo.Lang.Interpreter.Tests.dll `
        Boo.Lang.PatternMatching.Tests.dll `
        Boo.Lang.Useful.Tests.dll `
        BooCompilerResources.Tests.dll

    Write-TestResults .\TestResult.xml
    Pop-Location
}

Task Install-NUnitConsole -depends Init-All {
    choco install nunit-console-runner
    push-location tests/Boo.Lang.Tests
    $path = Get-NUnitPackageLocation /Boo.Lang.Tests.csproj
    pop-location
    Copy-Item $path Artifacts/
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

function Write-TestResults ($testreport_file)
{
    $xml = [xml](Get-Content $testreport_file)
    $xml.'test-run'.'test-suite' | ForEach-Object {
        if ($_.result -eq "Passed") {$color = [System.ConsoleColor]::Green}
        elseif ($_.result -eq "Skipped") {$color = [System.ConsoleColor]::Yellow}
        else {$color = [System.ConsoleColor]::Red}
        Write-Host -ForegroundColor Yellow "Name: $($_.name)"
        Write-Host -ForegroundColor $color "Result: $($_.result) Total Tests: $($_.total) Passed: $($_.passed) Failed: $($_.failed) Warnings: $($_.warnings) Inconclusive: $($_.inconclusive) Skipped: $($_.skipped)"
    }

}
function Get-ValueFromJSON ($json, $partial_key)
{
    $fieldName = ($json |Get-Member | Where-object Name -match $partial_key).Name
    $fieldValue = $json.$fieldName
    return $fieldName, $fieldValue
}