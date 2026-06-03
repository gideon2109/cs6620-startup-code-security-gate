import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Lock, Mail, ShieldAlert, Eye, EyeOff } from 'lucide-react';

function Login({ setUser }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    // Simple email domain check for academic grading environment
    const isEduEmail = email.toLowerCase().endsWith('.edu');
    
    setTimeout(() => {
      if (!isEduEmail) {
        setError('Please log in with a valid academic (.edu) email address.');
        setLoading(false);
        return;
      }

      if (email && password.length >= 6) {
        const username = email.split('@')[0];
        const formattedName = username.charAt(0).toUpperCase() + username.slice(1);
        const user = {
          email,
          name: formattedName,
          loginTime: new Date().toISOString()
        };
        localStorage.setItem('user', JSON.stringify(user));
        setUser(user);
        navigate('/dashboard');
      } else {
        setError('Password must be at least 6 characters long.');
        setLoading(false);
      }
    }, 600); // Small delay to simulate API verification transition
  };

  return (
    <div style={styles.container}>
      <div style={styles.card} className="animate-fade-in">
        <div style={styles.logoSection}>
          <div style={styles.iconWrapper}>
            <ShieldAlert size={32} color="#f8fafc" />
          </div>
          <h1 style={styles.title}>Startup Code Security Gate</h1>
          <p style={styles.subtitle}>SAST Scanner & Infrastructure Control</p>
        </div>

        {error && (
          <div style={styles.errorAlert}>
            <ShieldAlert size={18} style={{ marginRight: '8px', flexShrink: 0 }} />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleLogin} style={styles.form}>
          <div style={styles.inputGroup}>
            <label style={styles.label}>Northeastern / Academic Email</label>
            <div style={styles.inputContainer}>
              <Mail size={18} style={styles.inputIcon} />
              <input
                type="email"
                placeholder="your.email@northeastern.edu"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                style={styles.input}
                required
              />
            </div>
          </div>

          <div style={styles.inputGroup}>
            <label style={styles.label}>Access Token / Password</label>
            <div style={styles.inputContainer}>
              <Lock size={18} style={styles.inputIcon} />
              <input
                type={showPassword ? "text" : "password"}
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                style={styles.input}
                required
              />
              <button 
                type="button" 
                onClick={() => setShowPassword(!showPassword)}
                style={styles.togglePassword}
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          <button 
            type="submit" 
            style={loading ? {...styles.button, opacity: 0.7, cursor: 'wait'} : styles.button}
            disabled={loading}
          >
            {loading ? 'Verifying Credentials...' : 'Sign In'}
          </button>
        </form>

        <div style={styles.divider}></div>
        
        <div style={styles.footerNote}>
          <p>Group 9 Cloud Pipeline Demo. Sign in with any .edu email and password (min 6 characters) to access the dashboard console.</p>
        </div>
      </div>
    </div>
  );
}

const styles = {
  container: {
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    minHeight: '100vh',
    background: 'linear-gradient(135deg, #0f172a 0%, #0b0f19 100%)',
    padding: '20px',
  },
  card: {
    background: '#1e293b',
    borderRadius: '16px',
    border: '1px solid #334155',
    boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5)',
    width: '100%',
    maxWidth: '440px',
    padding: '40px',
    display: 'flex',
    flexDirection: 'column',
  },
  logoSection: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    marginBottom: '32px',
    textAlign: 'center',
  },
  iconWrapper: {
    background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
    width: '60px',
    height: '60px',
    borderRadius: '14px',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: '16px',
    boxShadow: '0 10px 25px -5px rgba(99, 102, 241, 0.4)',
  },
  title: {
    fontSize: '22px',
    fontWeight: '800',
    color: '#f8fafc',
    marginBottom: '6px',
  },
  subtitle: {
    fontSize: '13px',
    color: '#94a3b8',
    fontWeight: '500',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '20px',
  },
  inputGroup: {
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
  },
  label: {
    fontSize: '12px',
    fontWeight: '600',
    color: '#94a3b8',
    textTransform: 'uppercase',
    letterSpacing: '0.05em',
  },
  inputContainer: {
    position: 'relative',
    display: 'flex',
    alignItems: 'center',
  },
  inputIcon: {
    position: 'absolute',
    left: '12px',
    color: '#64748b',
  },
  input: {
    width: '100%',
    padding: '12px 16px 12px 42px',
    background: '#0f172a',
    border: '1px solid #334155',
    borderRadius: '8px',
    color: '#f8fafc',
    fontSize: '14px',
    outline: 'none',
    transition: 'border-color 0.2s ease',
    fontFamily: 'inherit',
  },
  togglePassword: {
    position: 'absolute',
    right: '12px',
    background: 'none',
    border: 'none',
    color: '#64748b',
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    outline: 'none',
  },
  button: {
    background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
    color: 'white',
    padding: '14px',
    border: 'none',
    borderRadius: '8px',
    fontSize: '15px',
    fontWeight: '600',
    cursor: 'pointer',
    boxShadow: '0 4px 14px 0 rgba(99, 102, 241, 0.4)',
    transition: 'transform 0.15s ease, opacity 0.2s ease',
  },
  errorAlert: {
    background: 'rgba(244, 63, 94, 0.15)',
    border: '1px solid rgba(244, 63, 94, 0.3)',
    borderRadius: '8px',
    padding: '12px',
    color: '#fb7185',
    fontSize: '13px',
    marginBottom: '20px',
    display: 'flex',
    alignItems: 'center',
  },
  divider: {
    height: '1px',
    background: '#334155',
    margin: '28px 0',
  },
  footerNote: {
    textAlign: 'center',
    color: '#64748b',
    fontSize: '11px',
    lineHeight: '1.5',
  }
};

export default Login;
