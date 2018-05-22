using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Text;
using System.Security.Cryptography;
using System.IO;

namespace CRPlasticoWeb.BussinesLayer.Classes
{
	public class SecurityInfo
	{

		private string pstrUsuario;
		private string pstrClave;

		public SecurityInfo()
		{
			pstrUsuario = string.Empty;
			pstrClave = string.Empty;
		}

		public string Usuario
		{
			set { pstrUsuario = value; }
			get { return pstrUsuario; }
		}

		public string Clave
		{
			set { pstrClave = value; }
			get { return pstrClave; }
		}

		/// <summary>
		/// Cifra una cadena de texto con el algoritmo Rijndael
		/// </summary>
		/// <param name="cadena">Cadena de texto sin cifrar</param>
		/// <returns>Texto cifrado</returns>
		public string decryptString(String cadenaCifrada)
		{

			int keySize = 32;
			int ivSize = 16;

			//Para contraseña del usuario en el SW ConsultaPedidosGcom
			byte[] key = UTF8Encoding.UTF8.GetBytes("G4ndH1");//Clave de cifrado para el algoritmo
			byte[] iv = UTF8Encoding.UTF8.GetBytes("G4ndH1C0m5w");//Vector de inicio para el algoritmo

			// Garantizar el tamaño correcto de la clave y el vector de inicio
			// mediante substring o padding
			Array.Resize<byte>(ref key, keySize);
			Array.Resize<byte>(ref iv, ivSize);

			// Obtener la representación en bytes del texto cifrado
			byte[] mensajeCifradoBytes = Convert.FromBase64String(cadenaCifrada);

			// Crear un arreglo de bytes para almacenar los datos descifrados
			byte[] cadenaBytes = new byte[mensajeCifradoBytes.Length];

			// Crear una instancia del algoritmo de Rijndael
			Rijndael rijndael = Rijndael.Create();

			// Crear un flujo en memoria con la representación de bytes de la información cifrada
			MemoryStream memoryStrm = new MemoryStream(mensajeCifradoBytes);

			// Crear un flujo de descifrado basado en el flujo de los datos
			CryptoStream flujoCifrado = new CryptoStream(memoryStrm, rijndael.CreateDecryptor(key, iv), CryptoStreamMode.Read);

			// Obtener los datos descifrados obteniéndolos del flujo de descifrado
			int decryptedByteCount = flujoCifrado.Read(cadenaBytes, 0, cadenaBytes.Length);

			// Cerrar los flujos utilizados
			memoryStrm.Close();
			flujoCifrado.Close();

			// Retornar la representación de texto de los datos descifrados
			return Encoding.UTF8.GetString(cadenaBytes, 0, decryptedByteCount);
		}
	}
}