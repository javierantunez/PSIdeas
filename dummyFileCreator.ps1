[string]$OutPath='OUTPUTFOLDER PATH';
$ExtraSmallSize = 1048576;
$ExtraSmallQty = 3999;

$NormalSmallSize = 2097152;
$NormalSmallQty=1999;

$SmallSize=5242880;
$SmallQty=799;

$NormalSize = 10485760;
$NormalQty=399;

$DoubleNormalSize= 20971520;
$DoubleNormalQty=199;

$MediumSize = 104857600;
$MediumSizeQty=39;

$LargeSize= 262144000;
$LargeQty=15;

$ExtraLargeSize=1073741824;
$ExtraLargeQty= 3;

function Createfiles ($varQty,$varSize,$OutPath)
{    
  write-host "Tamaño:" $varSize;     
  Write-Host "Cantidad:" $varQty;
  Write-host "Path salida:" $Outpath;
  for ($i=0; $i -le $varQty; $i++)
  {
    $OutFile=$Outpath+'DummyFile_'+(Get-Date -UFormat '%Y-%m-%d_%H-%m-%S-%M')+ (Get-random) +'.txt';
    $Content = new-object byte[] $varSize;
    (new-object Random).NextBytes($Content);
    [IO.File]::WriteAllBytes($OutFile, $Content);
  };
};

Createfiles -varQty $ExtraSmallQty -varSize $ExtraSmallSize -OutPath $OutPath;
Createfiles -varQty $NormalSmallQty -varSize $NormalSmallSize -OutPath $OutPath;
Createfiles -varQty $SmallQty -varSize $SmallSize -OutPath $OutPath;
Createfiles -varQty $NormalQty -varSize $NormalSize -OutPath $OutPath;
Createfiles -varQty $DoubleNormalQty -varSize $DoubleNormalSize -OutPath $OutPath;
Createfiles -varQty $MediumSizeQty -varSize $MediumSize -OutPath $OutPath;
Createfiles -varQty $LargeQty -varSize $LargeSize -OutPath $OutPath;
Createfiles -varQty $ExtraLargeQty -varSize $ExtraLargeSize -OutPath $OutPath;
