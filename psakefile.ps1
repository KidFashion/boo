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
    Write-Host join-path (Get-Location) "bin\Debug\net48\booc.exe"
    $script:booc = join-path (Get-Location) "bin\Debug\net48\booc.exe"
    Write-Host $booc
    pop-location
}

Task Build-BooCore -depends Build-BooLang, Build-BooLangCompiler, Build-BooLangParser{
}

Task Build-BooLangExtensions -depends Build-BooCompilerTool {
    Push-Location src/Boo.Lang.Extensions
    &$script:booc `
        -o:Boo.Lang.Extensions.dll `
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

Task Build-BooLangPatternMatching -depends Build-BooCompilerTool {
    Push-Location src/Boo.Lang.PatternMatching
    &$script:booc `
        -o:Boo.Lang.PatternMatching.dll `
        -srcdir:.
    pop-location
}

Task Build-BooLangInterpreter -depends Build-BooCompilerTool, Build-BooLangPatternMatching {
    Push-Location src/Boo.Lang.Interpreter
    &$script:booc `
        -o:Boo.Lang.Interpreter.dll `
        -srcdir:. `
        -r:../Boo.Lang.PatternMatching/Boo.Lang.PatternMatching.dll
    pop-location
}

Task Build-BooLangUseful -depends Build-BooCompilerTool {
    Push-Location src/Boo.Lang.Useful
    &$script:booc `
        -o:Boo.Lang.Useful.dll `
        -srcdir:. `
        -r:../Boo.Lang.Parser/bin/Debug/net48/Boo.Lang.Parser.dll
    pop-location
}


Task Build-Booi -depends Build-BooCompilerTool, Build-BooLangUseful {
    Push-Location src/Booi
    &$script:booc `
        -o:booi.exe `
        -srcdir:. `
        -r:../Boo.Lang.Useful/Boo.Lang.Useful.dll
    pop-location
}

Task Build-Booish -depends Build-BooCompilerTool, Build-BooLangInterpreter {
    Push-Location src/Booish
    &$script:booc `
        -o:booish.exe `
        -r:../Boo.Lang.Interpreter/Boo.Lang.Interpreter.dll `
        booish.boo
    pop-location
}

Task Build-BooLangCodeDom -depends Build-BooCompilerTool {
    Push-Location src/Boo.Lang.CodeDom
    &$script:booc `
        -o:Boo.Lang.CodeDom.dll `
        -srcdir:.
    pop-location
}
