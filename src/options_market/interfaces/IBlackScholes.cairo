%lang starknet

@contract_interface
namespace IBlackScholes {
    func option_prices(t_annualised, volatility, spot, strike, rate) -> (call_price : felt, put_price : felt){
    }
}