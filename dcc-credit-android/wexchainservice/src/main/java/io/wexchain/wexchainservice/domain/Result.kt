package io.wexchain.wexchainservice.domain

import io.wexchain.wexchainservice.WexChainException
import io.reactivex.Single
import io.reactivex.SingleTransformer

/**
 * Created by lulingzhi on 2017/11/28.
 */
data class Result<out T>(
        @JvmField val systemCode: String,
        @JvmField val businessCode: String?,
        @JvmField val result: T?,
        @JvmField val trace: String?,
        @JvmField val message: String?
) {

    val isSuccess: Boolean
        get() {
            return systemCode == SUCCESS && businessCode == SUCCESS
        }

    fun asError(): Exception {
        return WexChainException(message, systemCode, businessCode)
    }

    companion object {
        const val SUCCESS = "SUCCESS"

        fun <T> checkedAllowingNull(whenNull: T): SingleTransformer<Result<T>, T> {
            return SingleTransformer { upstream ->
                return@SingleTransformer upstream
                        .map { resp ->
                            if (resp.isSuccess) {
                                resp.result ?: whenNull
                            } else {
                                throw resp.asError()
                            }
                        }
            }
        }

        fun <T> checked(): SingleTransformer<Result<T>, T> {
            return SingleTransformer { upstream ->
                return@SingleTransformer upstream
                        .flatMap { resp ->
                            if (resp.isSuccess && resp.result != null) {
                                return@flatMap Single.just(resp.result)
                            } else {
                                return@flatMap Single.error<T>(resp.asError())
                            }
                        }
            }
        }
    }
}