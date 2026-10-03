// The filter itself: one colour matrix laid over the whole screen by the Magnification
// API, the same one Windows' own colour filters use. Gray, amber and dimming are a
// single matrix, so the picture is the same as GNOME's shader: luminance of the stored
// values, times the 1900 K tint, times the brightness.
//
// The effect belongs to this process. Windows removes it when the process ends, even
// by a crash, so the screen can never be left amber by accident.

using System;
using System.Runtime.InteropServices;

namespace ReadersNight
{
    static class Filter
    {
        // Amber: a black body at 1900 K, the coolest that has no blue (see tools/amber.py).
        static readonly float[] Tint = { 1.0f, 0.5167f, 0.0f };
        // Luminance of a colour, Rec. 709.
        static readonly float[] Luma = { 0.2126f, 0.7152f, 0.0722f };

        [StructLayout(LayoutKind.Sequential)]
        struct MagColorEffect
        {
            [MarshalAs(UnmanagedType.ByValArray, SizeConst = 25)]
            public float[] transform;
        }

        [DllImport("Magnification.dll", SetLastError = true)]
        static extern bool MagInitialize();

        [DllImport("Magnification.dll", SetLastError = true)]
        static extern bool MagUninitialize();

        [DllImport("Magnification.dll", SetLastError = true)]
        static extern bool MagSetFullscreenColorEffect(ref MagColorEffect effect);

        [DllImport("Magnification.dll", SetLastError = true)]
        static extern bool MagGetFullscreenColorEffect(ref MagColorEffect effect);

        static bool initialized;

        public static bool Initialize()
        {
            if (!initialized)
            {
                try { initialized = MagInitialize(); }
                catch (Exception) { initialized = false; }
            }
            return initialized;
        }

        public static void Shutdown()
        {
            if (!initialized) return;
            Set(Identity());
            MagUninitialize();
            initialized = false;
        }

        // The matrix works on row vectors: [r g b a 1] × M. Row i says how much of input
        // channel i goes into each output column.
        public static float[] Matrix(bool gray, int brightness)
        {
            var m = new float[25];
            float dim = brightness / 100f;
            for (int output = 0; output < 3; output++)
            {
                for (int input = 0; input < 3; input++)
                {
                    float share = gray ? Luma[input] : (input == output ? 1f : 0f);
                    m[input * 5 + output] = share * Tint[output] * dim;
                }
            }
            m[3 * 5 + 3] = 1f;
            m[4 * 5 + 4] = 1f;
            return m;
        }

        public static float[] Identity()
        {
            var m = new float[25];
            for (int i = 0; i < 5; i++) m[i * 5 + i] = 1f;
            return m;
        }

        public static bool Set(float[] matrix)
        {
            if (!Initialize()) return false;
            var effect = new MagColorEffect { transform = matrix };
            return MagSetFullscreenColorEffect(ref effect);
        }

        // The matrix on screen now, or null if it cannot be read.
        public static float[] Current()
        {
            if (!Initialize()) return null;
            var effect = new MagColorEffect { transform = new float[25] };
            return MagGetFullscreenColorEffect(ref effect) ? effect.transform : null;
        }

        public static bool Same(float[] a, float[] b)
        {
            if (a == null || b == null) return false;
            for (int i = 0; i < 25; i++)
                if (Math.Abs(a[i] - b[i]) > 1e-4f) return false;
            return true;
        }
    }
}
