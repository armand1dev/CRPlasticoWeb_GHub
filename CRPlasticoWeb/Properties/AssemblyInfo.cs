using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

// General Information about an assembly is controlled through the following 
// set of attributes. Change these attribute values to modify the information
// associated with an assembly.
[assembly: AssemblyTitle("CRPlasticoWeb")]
[assembly: AssemblyDescription("")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("")]
[assembly: AssemblyProduct("CRPlasticoWeb")]
[assembly: AssemblyCopyright("Copyright ©  2017")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]

// Setting ComVisible to false makes the types in this assembly not visible 
// to COM components.  If you need to access a type in this assembly from 
// COM, set the ComVisible attribute to true on that type.
[assembly: ComVisible(false)]

// The following GUID is for the ID of the typelib if this project is exposed to COM
[assembly: Guid("7baf27ba-9d45-47aa-a390-23dba2ec0e1a")]

// Version information for an assembly consists of the following four values:
//
//      Major Version
//      Minor Version 
//      Build Number
//      Revision
//
// You can specify all the values or you can default the Revision and Build Numbers 
// by using the '*' as shown below:

/**
 * 13/10/2017
 * David Galicia
 * Se volvio a desarrollar el proyecto en Visual Studio 2012 debido a que no fue posible 
 * editar la version anterior .
 * 
 * Se creo la  tabla ValesCfg para la configuracion de los objetos
 * 
 * Se crearon los siguientes objetos de base de datos:
 * 
 * - CRPlasticoSaldoSPS: Consulta el saldo del CR disminuyendo lo que se haya utilizado en los pedidos GCOM
 * - CRPlasticoActualizaSPU: Activa el CR 
 * 
 * Estos SP sustituyen a las consultas en codigo 'duro' de la anterior version.
 * 
 * **/
/*[assembly: AssemblyVersion("2.0.0.0")]
[assembly: AssemblyFileVersion("2.0.0.0")]*/

/*2018021800(1) Agregar método para redimir puntos de CR plásticos*/
[assembly: AssemblyVersion("2.0.0.1")]
[assembly: AssemblyFileVersion("2.0.0.1")]

/*2018051600(1) Nuevo método para obtener Certificados de regalo de Gcom*/
[assembly: AssemblyVersion("2.0.0.2")]
[assembly: AssemblyFileVersion("2.0.0.2")]
