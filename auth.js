// 認證頁面 JavaScript - 玻璃擬態登入/註冊系統

class AuthSystem {
  constructor() {
    this.currentTab = 'login';
    this.otpTimer = null;
    this.otpCountdown = 60;
    this.isOtpDialogOpen = false;
    this.currentPhone = '';
    
    this.init();
  }

  init() {
    this.setupTabSwitching();
    this.setupKeyboardNavigation();
    this.setupPhoneInput();
    this.setupSocialLogin();
    this.setupOtpDialog();
    this.setupFormSubmission();
    this.setupAccessibility();
  }

  // 標籤切換功能
  setupTabSwitching() {
    const tabButtons = document.querySelectorAll('.tab-button');
    const tabPanels = document.querySelectorAll('.tab-panel');

    tabButtons.forEach(button => {
      button.addEventListener('click', (e) => {
        const targetTab = e.target.dataset.tab;
        this.switchTab(targetTab);
      });
    });
  }

  switchTab(tabName) {
    const tabButtons = document.querySelectorAll('.tab-button');
    const tabPanels = document.querySelectorAll('.tab-panel');

    // 更新按鈕狀態
    tabButtons.forEach(button => {
      button.classList.toggle('active', button.dataset.tab === tabName);
      button.setAttribute('aria-selected', button.dataset.tab === tabName);
    });

    // 更新面板顯示
    tabPanels.forEach(panel => {
      panel.classList.toggle('active', panel.id === `${tabName}-panel`);
      panel.setAttribute('aria-hidden', panel.id !== `${tabName}-panel`);
    });

    this.currentTab = tabName;
    
    // 更新頁面標題和描述
    this.updateTabContent(tabName);
  }

  updateTabContent(tabName) {
    const title = document.querySelector('.auth-title');
    const subtitle = document.querySelector('.auth-subtitle');
    const primaryBtn = document.querySelector('.primary-btn');

    if (tabName === 'login') {
      title.textContent = '歡迎回來';
      subtitle.textContent = '登入您的帳戶以繼續使用';
      primaryBtn.textContent = '以手機號碼登入';
    } else {
      title.textContent = '建立帳戶';
      subtitle.textContent = '註冊新帳戶開始您的旅程';
      primaryBtn.textContent = '以手機號碼註冊';
    }
  }

  // 鍵盤導航支援
  setupKeyboardNavigation() {
    const tabContainer = document.querySelector('.tab-container');
    
    tabContainer.addEventListener('keydown', (e) => {
      const tabButtons = Array.from(document.querySelectorAll('.tab-button'));
      const currentIndex = tabButtons.findIndex(btn => btn === document.activeElement);
      
      let newIndex = currentIndex;
      
      switch (e.key) {
        case 'ArrowLeft':
          e.preventDefault();
          newIndex = currentIndex > 0 ? currentIndex - 1 : tabButtons.length - 1;
          break;
        case 'ArrowRight':
          e.preventDefault();
          newIndex = currentIndex < tabButtons.length - 1 ? currentIndex + 1 : 0;
          break;
        case 'Home':
          e.preventDefault();
          newIndex = 0;
          break;
        case 'End':
          e.preventDefault();
          newIndex = tabButtons.length - 1;
          break;
        default:
          return;
      }
      
      tabButtons[newIndex].focus();
      this.switchTab(tabButtons[newIndex].dataset.tab);
    });
  }

  // 手機號碼輸入處理
  setupPhoneInput() {
    const phoneInput = document.querySelector('.phone-input');
    
    phoneInput.addEventListener('input', (e) => {
      let value = e.target.value.replace(/\D/g, ''); // 只保留數字
      
      // 台灣手機號碼格式化 (09xx-xxx-xxx)
      if (value.startsWith('09') && value.length <= 10) {
        if (value.length > 4 && value.length <= 7) {
          value = value.slice(0, 4) + '-' + value.slice(4);
        } else if (value.length > 7) {
          value = value.slice(0, 4) + '-' + value.slice(4, 7) + '-' + value.slice(7);
        }
      }
      
      e.target.value = value;
      this.validatePhoneNumber(value);
    });

    phoneInput.addEventListener('keydown', (e) => {
      // 允許的按鍵：數字、退格、刪除、方向鍵、Tab
      const allowedKeys = [
        'Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Tab',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
      ];
      
      if (!allowedKeys.includes(e.key) && !e.ctrlKey && !e.metaKey) {
        e.preventDefault();
      }
    });
  }

  validatePhoneNumber(phone) {
    const cleanPhone = phone.replace(/\D/g, '');
    const errorElement = document.querySelector('.error-message');
    
    if (cleanPhone.length === 0) {
      errorElement.textContent = '';
      return false;
    }
    
    if (!cleanPhone.startsWith('09') || cleanPhone.length !== 10) {
      errorElement.textContent = '請輸入有效的台灣手機號碼 (09xx-xxx-xxx)';
      return false;
    }
    
    errorElement.textContent = '';
    return true;
  }

  // 第三方登入模擬
  setupSocialLogin() {
    const googleBtn = document.querySelector('.google-btn');
    const appleBtn = document.querySelector('.apple-btn');

    googleBtn.addEventListener('click', () => {
      console.log('Google 登入/註冊 - 模擬點擊');
      this.showToast('Google 登入功能開發中...', 'info');
    });

    appleBtn.addEventListener('click', () => {
      console.log('Apple 登入/註冊 - 模擬點擊');
      this.showToast('Apple 登入功能開發中...', 'info');
    });
  }

  // OTP 對話框設置
  setupOtpDialog() {
    const overlay = document.querySelector('.otp-overlay');
    const otpInputs = document.querySelectorAll('.otp-input');
    const resendBtn = document.querySelector('.otp-resend');
    const cancelBtn = document.querySelector('.otp-cancel');
    const confirmBtn = document.querySelector('.otp-confirm');

    // OTP 輸入處理
    otpInputs.forEach((input, index) => {
      input.addEventListener('input', (e) => {
        const value = e.target.value;
        
        // 只允許數字
        if (!/^\d$/.test(value) && value !== '') {
          e.target.value = '';
          return;
        }
        
        if (value) {
          input.classList.add('filled');
          input.classList.remove('error');
          
          // 自動跳到下一個輸入框
          if (index < otpInputs.length - 1) {
            otpInputs[index + 1].focus();
          }
        } else {
          input.classList.remove('filled');
        }
        
        this.checkOtpComplete();
      });

      input.addEventListener('keydown', (e) => {
        if (e.key === 'Backspace' && !input.value && index > 0) {
          // 退格鍵回到上一個輸入框
          otpInputs[index - 1].focus();
          otpInputs[index - 1].value = '';
          otpInputs[index - 1].classList.remove('filled');
        }
      });

      input.addEventListener('paste', (e) => {
        e.preventDefault();
        const pasteData = e.clipboardData.getData('text');
        const digits = pasteData.replace(/\D/g, '').slice(0, 6);
        
        if (digits.length === 6) {
          otpInputs.forEach((otpInput, i) => {
            otpInput.value = digits[i] || '';
            otpInput.classList.toggle('filled', !!digits[i]);
          });
          this.checkOtpComplete();
        }
      });
    });

    // 重新發送 OTP
    resendBtn.addEventListener('click', () => {
      this.resendOtp();
    });

    // 取消按鈕
    cancelBtn.addEventListener('click', () => {
      this.closeOtpDialog();
    });

    // 確認按鈕
    confirmBtn.addEventListener('click', () => {
      this.verifyOtp();
    });

    // 點擊遮罩關閉
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        this.closeOtpDialog();
      }
    });

    // ESC 鍵關閉
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && this.isOtpDialogOpen) {
        this.closeOtpDialog();
      }
    });
  }

  // 表單提交處理
  setupFormSubmission() {
    const primaryBtn = document.querySelector('.primary-btn');
    
    primaryBtn.addEventListener('click', (e) => {
      e.preventDefault();
      this.handlePhoneLogin();
    });
  }

  handlePhoneLogin() {
    const phoneInput = document.querySelector('.phone-input');
    const phone = phoneInput.value;
    
    if (!this.validatePhoneNumber(phone)) {
      phoneInput.focus();
      return;
    }
    
    this.currentPhone = phone;
    this.showOtpDialog(phone);
  }

  showOtpDialog(phone) {
    const overlay = document.querySelector('.otp-overlay');
    const phoneDisplay = document.querySelector('.otp-phone');
    const otpInputs = document.querySelectorAll('.otp-input');
    
    phoneDisplay.textContent = phone;
    
    // 清空 OTP 輸入
    otpInputs.forEach(input => {
      input.value = '';
      input.classList.remove('filled', 'error');
    });
    
    overlay.classList.add('active');
    this.isOtpDialogOpen = true;
    
    // 聚焦第一個輸入框
    setTimeout(() => {
      otpInputs[0].focus();
    }, 300);
    
    // 開始倒數計時
    this.startOtpCountdown();
    
    // 模擬發送 OTP
    console.log(`模擬發送 OTP 到 ${phone}`);
    this.showToast(`驗證碼已發送至 ${phone}`, 'success');
  }

  closeOtpDialog() {
    const overlay = document.querySelector('.otp-overlay');
    overlay.classList.remove('active');
    this.isOtpDialogOpen = false;
    
    if (this.otpTimer) {
      clearInterval(this.otpTimer);
      this.otpTimer = null;
    }
  }

  checkOtpComplete() {
    const otpInputs = document.querySelectorAll('.otp-input');
    const confirmBtn = document.querySelector('.otp-confirm');
    const allFilled = Array.from(otpInputs).every(input => input.value);
    
    confirmBtn.disabled = !allFilled;
  }

  verifyOtp() {
    const otpInputs = document.querySelectorAll('.otp-input');
    const otp = Array.from(otpInputs).map(input => input.value).join('');
    const errorElement = document.querySelector('.otp-error');
    
    // 模擬 OTP 驗證 (假設 123456 為正確驗證碼)
    if (otp === '123456') {
      errorElement.textContent = '';
      this.closeOtpDialog();
      
      // 成功流程
      setTimeout(() => {
        alert('登入成功！');
        // location.href = './dashboard.html'; // 暫時註解
        console.log('將導向 dashboard.html');
      }, 500);
    } else {
      errorElement.textContent = '驗證碼錯誤，請重新輸入';
      
      // 標記錯誤狀態
      otpInputs.forEach(input => {
        input.classList.add('error');
        input.value = '';
        input.classList.remove('filled');
      });
      
      // 聚焦第一個輸入框
      setTimeout(() => {
        otpInputs[0].focus();
      }, 500);
    }
  }

  startOtpCountdown() {
    const resendBtn = document.querySelector('.otp-resend');
    this.otpCountdown = 60;
    resendBtn.disabled = true;
    
    const updateCountdown = () => {
      if (this.otpCountdown > 0) {
        resendBtn.textContent = `重新發送 (${this.otpCountdown}s)`;
        this.otpCountdown--;
      } else {
        resendBtn.textContent = '重新發送驗證碼';
        resendBtn.disabled = false;
        clearInterval(this.otpTimer);
        this.otpTimer = null;
      }
    };
    
    updateCountdown();
    this.otpTimer = setInterval(updateCountdown, 1000);
  }

  resendOtp() {
    console.log(`重新發送 OTP 到 ${this.currentPhone}`);
    this.showToast(`驗證碼已重新發送至 ${this.currentPhone}`, 'success');
    this.startOtpCountdown();
  }

  // 無障礙設置
  setupAccessibility() {
    // 為動態內容添加 live region
    const liveRegion = document.createElement('div');
    liveRegion.setAttribute('aria-live', 'polite');
    liveRegion.setAttribute('aria-atomic', 'true');
    liveRegion.className = 'sr-only';
    liveRegion.id = 'live-region';
    document.body.appendChild(liveRegion);
    
    // 設置初始 ARIA 屬性
    const tabButtons = document.querySelectorAll('.tab-button');
    const tabPanels = document.querySelectorAll('.tab-panel');
    
    tabButtons.forEach((button, index) => {
      button.setAttribute('role', 'tab');
      button.setAttribute('aria-controls', `${button.dataset.tab}-panel`);
      button.setAttribute('aria-selected', index === 0 ? 'true' : 'false');
    });
    
    tabPanels.forEach((panel, index) => {
      panel.setAttribute('role', 'tabpanel');
      panel.setAttribute('aria-hidden', index === 0 ? 'false' : 'true');
    });
  }

  // Toast 通知系統
  showToast(message, type = 'info') {
    // 移除現有 toast
    const existingToast = document.querySelector('.toast');
    if (existingToast) {
      existingToast.remove();
    }
    
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    toast.setAttribute('role', 'alert');
    toast.setAttribute('aria-live', 'assertive');
    
    document.body.appendChild(toast);
    
    // 顯示動畫
    setTimeout(() => {
      toast.classList.add('show');
    }, 100);
    
    // 自動隱藏
    setTimeout(() => {
      toast.classList.remove('show');
      setTimeout(() => {
        if (toast.parentNode) {
          toast.remove();
        }
      }, 400);
    }, 3000);
  }

  // 宣告狀態變更給螢幕閱讀器
  announceToScreenReader(message) {
    const liveRegion = document.getElementById('live-region');
    if (liveRegion) {
      liveRegion.textContent = message;
      setTimeout(() => {
        liveRegion.textContent = '';
      }, 1000);
    }
  }
}

// 頁面載入完成後初始化
document.addEventListener('DOMContentLoaded', () => {
  new AuthSystem();
  
  // 設置初始焦點
  const firstTabButton = document.querySelector('.tab-button');
  if (firstTabButton) {
    firstTabButton.focus();
  }
});

// 導出類別供其他模組使用
if (typeof module !== 'undefined' && module.exports) {
  module.exports = AuthSystem;
}