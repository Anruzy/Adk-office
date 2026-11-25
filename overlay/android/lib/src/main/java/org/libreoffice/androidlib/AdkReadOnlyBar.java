/* -*- Mode: Java; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Adk-office: barra "Solo lectura · Habilitar edición".
 *
 * Los archivos que llegan por WhatsApp, correo o descargas suelen abrirse sin
 * permiso de escritura, y la app los muestra en solo lectura. Esta barra (al
 * estilo de la "Vista protegida" de Excel) ofrece habilitar la edición: se
 * guarda una copia editable donde el usuario elija (memoria interna, SD,
 * Drive...) y el documento pasa a modo edición sin recargarse.
 */

package org.libreoffice.androidlib;

import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowInsets;
import android.widget.FrameLayout;

import com.google.android.material.snackbar.Snackbar;

final class AdkReadOnlyBar {
    private static Snackbar sBar;
    private static boolean sShownForThisDocument;

    private AdkReadOnlyBar() {}

    /** Se llama cuando el documento termina de mostrarse. */
    static void onDocumentShown(final LOActivity activity, final boolean editable,
                                final boolean canBeExported) {
        if (editable || sShownForThisDocument)
            return;
        sShownForThisDocument = true;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                show(activity, canBeExported);
            }
        });
    }

    /** Reinicia el estado al abrir otro documento. */
    static void reset() {
        sShownForThisDocument = false;
        dismiss();
    }

    static void dismiss() {
        if (sBar != null) {
            sBar.dismiss();
            sBar = null;
        }
    }

    private static void show(final LOActivity activity, boolean canBeExported) {
        View anchor = activity.findViewById(R.id.browser);
        if (anchor == null)
            anchor = activity.findViewById(android.R.id.content);
        if (anchor == null)
            return;

        int message = canBeExported ? R.string.adk_readonly_message
                                    : R.string.adk_readonly_message_convert;
        sBar = Snackbar.make(anchor, message, Snackbar.LENGTH_INDEFINITE);
        sBar.setAction(R.string.adk_enable_editing, new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                sBar = null;
                activity.adkEnableEditing();
            }
        });

        // Arriba, como la barra de Excel, para no tapar las pestañas de
        // hojas ni la barra de herramientas inferior.
        View barView = sBar.getView();
        ViewGroup.LayoutParams lp = barView.getLayoutParams();
        if (lp instanceof FrameLayout.LayoutParams) {
            FrameLayout.LayoutParams flp = (FrameLayout.LayoutParams) lp;
            flp.gravity = Gravity.TOP | Gravity.CENTER_HORIZONTAL;
            WindowInsets insets = anchor.getRootWindowInsets();
            if (insets != null)
                flp.topMargin += insets.getSystemWindowInsetTop();
            barView.setLayoutParams(flp);
        }
        sBar.setAnimationMode(Snackbar.ANIMATION_MODE_FADE);
        sBar.show();
    }
}

/* vim:set shiftwidth=4 softtabstop=4 expandtab: */
