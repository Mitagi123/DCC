package io.wexchain.android.dcc.fragment

import android.os.Bundle
import android.view.View
import com.wexmarket.android.passport.base.BindFragment
import io.wexchain.android.common.getViewModel
import io.wexchain.android.dcc.constant.Extras
import io.wexchain.android.dcc.vm.VerifyBankCardSmsCodeVm
import io.wexchain.auth.R
import io.wexchain.auth.databinding.FragmentVerifyBankSmsCodeBinding

class VerifyBankSmsCodeFragment : BindFragment<FragmentVerifyBankSmsCodeBinding>() {
    override val contentLayoutId: Int = R.layout.fragment_verify_bank_sms_code

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val viewModel = getViewModel<VerifyBankCardSmsCodeVm>().apply {
            phoneNo.set(phoneNum)
        }
        binding.vm = viewModel
        binding.btnSendSmsCode.setOnClickListener {
            listener?.requestReSendSmsCode()
            viewModel.code.set("")
        }
        binding.btnSubmitCode.setOnClickListener {
            viewModel.code.get()?.let {
                //todo check
                listener?.onSubmitSmsCode(it)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        activity!!.setTitle(R.string.title_verify_sms_code)
    }

    var phoneNum:String
        get() = arguments?.getString(Extras.EXTRA_BANK_CARD_PHONE_NUM)?:""
        set(value) {
            if(arguments == null){
                    arguments = Bundle()
                }
            arguments!!.putString(Extras.EXTRA_BANK_CARD_PHONE_NUM, value)
        }

    private var listener:Listener? = null

    interface Listener{
        fun onSubmitSmsCode(code: String)
        fun requestReSendSmsCode()
    }

    companion object {
        fun create(listener: Listener): VerifyBankSmsCodeFragment {
            val fragment = VerifyBankSmsCodeFragment()
            fragment.listener = listener
            return fragment
        }
    }
}