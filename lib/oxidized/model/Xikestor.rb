class Xlikestor < Oxidized::Model

  # この行が `cut_both` メソッドを利用可能にします
  using Refinements

  # (10G-L2) > や (10G-L2) # にマッチ
  prompt /([\w\s\(\).-]+[#>]\s?)$/
  comment '! '

  # ログインプロンプト
  expect /^User(name)?: $/i do |data, re|
    send vars(:username) + "\n"
    data.sub re, ''
  end

  expect /^Password: $/i do |data, re|
    send vars(:password) + "\n"
    data.sub re, ''
  end

  # エラーメッセージをクリーニング
  cmd :all do |cfg|
    cfg.gsub! /^% Invalid input detected at '\^' marker\.$|^\s+\^$/, ''
    cfg.cut_both
  end

  # メインの設定取得とクリーニング
  post do
    cmd 'show running-config' do |cfg|

      # ログに基づき、動的な行を削除
      cfg.gsub! /^!System Up Time .*/, ''
      cfg.gsub! /^!Current SNTP Synchronized Time .*/, ''

      # コンフィグのヘッダーを削除
      cfg.gsub! /^!Current Configuration:[^\n]*\n/, ''

      # コンフィグのフッター (! end.) を削除
      cfg.gsub! /^! end\.$/, ''

      # 余分な空行を削除
      cfg.gsub! /^\s*$\n/, ''

      cfg.cut_both
    end
  end

  # ログイン/Enable/終了処理
  cfg :telnet, :ssh do

    # ログイン直後に実行 (enable 処理)
    post_login do
      # router.db の6番目のフィールド (vars(:enable)) をチェック
      if vars(:enable) == true
        cmd "enable"
      elsif vars(:enable)
        cmd "enable", /^[pP]assword:/i # "Password:" プロンプトを待機
        cmd vars(:enable)             # パスワードを送信
      end
      # vars(:enable) が未設定の場合は 'enable' を試みない
    end

    # 'enable' 処理の *後* に 'terminal length 0' を実行
    post_login 'terminal length 0'

    # 終了コマンド
    pre_logout 'logout'
  end

end