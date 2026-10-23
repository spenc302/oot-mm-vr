package com.ootvr.game;

import org.libsdl.app.SDLActivity;

public final class OotVRActivity extends SDLActivity {
    @Override
    protected String[] getLibraries() {
        return new String[] { "main" };
    }
}
