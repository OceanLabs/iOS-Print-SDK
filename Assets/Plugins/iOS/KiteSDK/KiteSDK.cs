using System.Collections;
using System.Collections.Generic;
using System;
using UnityEngine;
using System.Runtime.InteropServices;

public class KiteSDK : MonoBehaviour {

	public enum KiteEnvironment {Test, Live};

	[DllImport ("__Internal")]
	private static extern void _PresentKiteShop (string apiKey, int environment);

	// Presents the Kite shop screen. If needed, pause your game before calling this method
	public static void PresentKiteShop(string apiKey, KiteEnvironment environment)
	{
		#if UNITY_IPHONE
		// Call plugin only when running on real device
		if (Application.platform != RuntimePlatform.OSXEditor) {
			_PresentKiteShop (apiKey, (int)environment);

		}
		#endif
	}
}
