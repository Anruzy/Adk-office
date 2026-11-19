/* -*- Mode: Java; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Adk-office: elige dónde guardar las copias temporales de documentos.
 *
 * Al abrir un documento la app copia el archivo completo a un temporal, y al
 * exportar/imprimir genera otro. Con documentos grandes eso llena el
 * almacenamiento interno. Si hay una tarjeta SD montada (y el usuario no lo
 * desactivó en Ajustes), esas copias van a la carpeta privada de la app en la
 * SD: Android/data/<paquete>/cache. Si no, se usa la caché interna de siempre.
 */

package org.libreoffice.androidlib;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Environment;
import android.preference.PreferenceManager;
import android.util.Log;

import java.io.File;

public final class AdkStorage {
    private static final String TAG = "AdkStorage";

    /** Clave del interruptor en Ajustes (libreoffice_preferences.xml). */
    public static final String PREF_USE_SD = "adk_use_sd_cache";

    /** Espacio mínimo libre en la SD para preferirla. */
    private static final long MIN_FREE_BYTES = 64L * 1024 * 1024;

    /** Los temporales con más de un día se consideran huérfanos. */
    private static final long STALE_MS = 24L * 60 * 60 * 1000;

    private static boolean sCleaned = false;

    private AdkStorage() {}

    /**
     * Carpeta para copias temporales de documentos: la SD si está disponible
     * y habilitada; si no, la caché interna.
     */
    public static File documentCacheDir(Context context) {
        File internal = context.getCacheDir();
        File chosen = internal;
        if (isSdEnabled(context)) {
            File sd = removableCacheDir(context);
            if (sd != null)
                chosen = sd;
        }
        if (!sCleaned) {
            sCleaned = true;
            cleanStale(internal);
            if (chosen != internal)
                cleanStale(chosen);
        }
        return chosen;
    }

    /** true si hay una tarjeta SD utilizable en este momento. */
    public static boolean hasRemovableStorage(Context context) {
        return removableCacheDir(context) != null;
    }

    private static boolean isSdEnabled(Context context) {
        try {
            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
            return prefs.getBoolean(PREF_USE_SD, true);
        } catch (RuntimeException e) {
            return true;
        }
    }

    private static File removableCacheDir(Context context) {
        File[] dirs;
        try {
            dirs = context.getExternalCacheDirs();
        } catch (RuntimeException e) {
            return null;
        }
        if (dirs == null)
            return null;
        for (File dir : dirs) {
            if (dir == null)
                continue;
            try {
                if (!Environment.isExternalStorageRemovable(dir))
                    continue;
                if (!Environment.MEDIA_MOUNTED.equals(Environment.getExternalStorageState(dir)))
                    continue;
                if (!dir.exists() && !dir.mkdirs())
                    continue;
                if (!dir.canWrite() || dir.getUsableSpace() < MIN_FREE_BYTES)
                    continue;
                return dir;
            } catch (IllegalArgumentException e) {
                Log.w(TAG, "Almacenamiento no reconocido: " + dir, e);
            }
        }
        return null;
    }

    /** Borra temporales "LibreOffice*" y print.pdf viejos que quedaron de sesiones anteriores. */
    private static void cleanStale(File dir) {
        File[] files = dir.listFiles();
        if (files == null)
            return;
        long limit = System.currentTimeMillis() - STALE_MS;
        for (File f : files) {
            String name = f.getName();
            if (f.isFile() && (name.startsWith("LibreOffice") || name.equals("print.pdf"))
                    && f.lastModified() < limit) {
                if (!f.delete())
                    Log.w(TAG, "No se pudo borrar " + f);
            }
        }
    }
}

/* vim:set shiftwidth=4 softtabstop=4 expandtab: */
