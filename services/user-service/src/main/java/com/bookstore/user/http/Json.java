package com.bookstore.user.http;

import com.google.gson.Gson;

/** Turns objects into JSON text and back. The one place that knows which JSON library is used. */
public final class Json {

    private static final Gson GSON = new Gson();

    private Json() {
    }

    public static String write(Object value) {
        return GSON.toJson(value);
    }

    /** @throws com.google.gson.JsonSyntaxException if the text is not valid JSON */
    public static <T> T read(String text, Class<T> type) {
        return GSON.fromJson(text, type);
    }
}
