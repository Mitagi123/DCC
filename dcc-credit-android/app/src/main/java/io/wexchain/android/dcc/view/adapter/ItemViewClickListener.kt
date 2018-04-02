package io.wexchain.android.dcc.view.adapter

/**
 * Created by lulingzhi on 2017/9/8.
 */
interface ItemViewClickListener<in T> {
    fun onItemClick(item: T?, position: Int, viewId: Int)
}