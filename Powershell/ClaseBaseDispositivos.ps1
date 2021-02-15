Remove-Variable * -ErrorAction SilentlyContinue  
Class CadenaUtils
{
    Static [String] NumeroATexto10([Int32] $numero)
    {
        if ($numero -lt 10)
        {
            return "0$($numero)"
        }
        else {
            return "$($numero)"
        }
    }
    Static [String[]] FrasesEnTexto([String] $texto)
    {
        return $texto.Split(".");
    }
}

Class Dispositivo
{
    [ValidateNotNullOrEmpty()]
    [ValidateSet("t","o")]
    [String] $nombreDeEmpresa
    [ValidateNotNullOrEmpty()]
    [ValidateRange(1,99)]
    [int32] $numeroAula
    [ValidateNotNullOrEmpty()]
    [ValidateSet("w","p","g","s","u")]
    [String] $tipo
    [ValidateNotNullOrEmpty()]
    [ValidateRange(1,99)]
    [int32] $numeroOrdenador

    hidden Init([String] $nombreEmpresa, [Int32] $numeroAula, [String] $tipo, [Int32] $numeroOrdenador)
    {
        $this.nombreDeEmpresa = $nombreEmpresa
        $this.numeroAula = $numeroAula
        $this.tipo = $tipo
        $this.numeroOrdenador = $numeroOrdenador
    }
    Dispositivo ([String] $nombreEmpresa, [Int32] $numeroAula, [String] $tipo, [Int32] $numeroOrdenador)
    {
        $this.Init($nombreEmpresa,$numeroAula,$tipo,$numeroOrdenador)
    }
    Dispositivo ([String] $identificadorCompleto)
    {
        $this.Init($identificadorCompleto.Substring(0,1),
                            $identificadorCompleto.Substring(1,2) -as [Int32],
                            $identificadorCompleto.Substring(3,1),
                            $identificadorCompleto.Substring(4,2) -as [Int32])
    }
    [String] toString()
    {
        return "$($this.nombreDeEmpresa)$([cadenaUtils]::NumeroATexto10($this.numeroAula))$($this.tipo)$([cadenaUtils]::NumeroATexto10($this.numeroOrdenador))"
    }
}

Class DispositivoTajamar  : Dispositivo
{
    DispositivoTajamar ([Int32] $numeroAula, [String] $tipo, [Int32] $numeroOrdenador):
    base("t",$numeroAula,$tipo,$numeroOrdenador){}
}
Class DispositivoTajamarWorkStation : DispositivoTajamar
{
    DispositivoTajamarWorkStation ([Int32] $numeroAula, [Int32] $numeroOrdenador):
    base($numeroAula,"w",$numeroOrdenador){}
    arranca() 
    {
        Write-Host "arranca"
    }   
}
Class DispositivoTajamarPrinter : DispositivoTajamar
{
    DispositivoTajamarPrinter ([Int32] $numeroAula, [Int32] $numeroOrdenador):base($numeroAula,"p",$numeroOrdenador){}
    arranca()
    {
        Write-Host "prepara cartucho"
    }
}

Class ColeccionDeDispositivos
{
    [Dispositivo[]] $listaIdentificadores = $null
    ColeccionDeIdentificadores()
    {
        $this.listaIdentificadores = @()
    }
    [bool] existe ([Dispositivo] $dispositivo)
    {
        return $this.listaIdentificadores -contains $dispositivo
    }
    [void] pon ([Dispositivo] $identificador)
    {
        #Comprobaremos que no existe ya en la colección de Dispositivos.
        if (!$this.existe($identificador))
        {
            $this.listaIdentificadores+=($identificador)
        }
    }
    [int32] dameNumeroDeIdentificadores()
    {
        return [Linq.Enumerable]::Count($this.listaIdentificadores)
    }
    [int32] dameNumeroDeIdentificadoresPorAula ([int32] $numDeAula)
    {
        [int32] $contador  = 0
        foreach ($item in $this.listaIdentificadores)
        {
            if ($item.numeroAula -eq $numDeAula)
            {
                $contador++
            }
        }
        return $contador
    }
   
    [String] toString()
    {
        $cadena = ""
        foreach ($item in $this.listaIdentificadores) {
            $cadena += "$($item.toString())|"
        }
        return $cadena
    }


}

Class AulaTajamar : ColeccionDeDispositivos
{
      [Int32] $numeroAula
      AulaTajamar([Int32] $numeroAula)
      {
          $this.numeroAula = $numeroAula
      }
      PonDispositivoInterno ([DispositivoTajamar] $IdentificadorAPoner)
      {
          $this.pon($IdentificadorAPoner)
      }
}

$miDentificador0 = [DispositivoTajamar]::new(78,"s",2)
$miDentificador1 = [DispositivoTajamarPrinter]::new(3,29)
$miDentificador2 = [DispositivoTajamarWorkStation]::new(38,39)
$miDentificador3 = [Dispositivo]::new("o",11,"w",1)
$miDentificador4 = [Dispositivo]::new("t15w05")


$Coleccion = [AulaTajamar]::new(1)



$Coleccion.pon($miDentificador0);
$Coleccion.pon($miDentificador1);
$Coleccion.pon($miDentificador2);
$Coleccion.pon($miDentificador3);
$Coleccion.pon($miDentificador4);
