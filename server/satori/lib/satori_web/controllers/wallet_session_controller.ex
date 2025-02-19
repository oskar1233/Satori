defmodule SatoriWeb.WalletSessionController do
  use SatoriWeb, :controller

  alias Satori.Wallets
  alias Satori.Wallets.Wallet
  alias SatoriWeb.WalletAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{
        "wallet" =>
          %{"message" => message, "signature" => signature, "public_key" => public_key, "address" => address} = params
      }) do
    ## Add verify wallet here
    if verify!(message, signature, public_key) do
      if wallet = Wallets.get_wallet_by_address(public_key) do
        WalletAuth.log_in_wallet(conn, wallet, params)
      else
        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        render(conn, "new.html", error_message: "Invalid wallet")
      end
    else
      render(conn, "new.html", error_message: "Invalid wallet")
    end

    # if user = Accounts.get_user_by_public_key(public_key) do
    #   UserAuth.log_in_user(conn, user, user_params)
    # else
    #   render(conn, "wallet.html", error_message: "Invalid wallet")
    # end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> WalletAuth.log_out_wallet()
  end

  defp verify!(_message, _signature, _public_key) do
    if messageIsRecent(_message) do
      Satori.Wallets.Signature.verify!(_message, _signature, _public_key)
    end
    false
  end

  defp messageIsRecent(_message, _ago \\ -5) do
    {:ok, _compare} = Timex.parse(_message, "%Y-%m-%d %H:%M:%S.%f", :strftime)
    _messageTime = DateTime.from_naive!(_compare, "Etc/UTC")

    {:gt, :gt} ==
      {DateTime.compare(Timex.now(), _messageTime),
       DateTime.compare(_messageTime, Timex.shift(Timex.now(), seconds: _ago))}
  end
end
