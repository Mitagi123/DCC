package io.wexchain.android.dcc.tools


fun isPasswordValid(pw: String?): Boolean {
    return pw != null && pw.length in (2..20)
}

fun isKeyStoreValid(ks: String?): Boolean {
    return ks != null && ks.length >= 2
}

fun isEcPrivateKeyValid(key: String?): Boolean {
    return key != null
}