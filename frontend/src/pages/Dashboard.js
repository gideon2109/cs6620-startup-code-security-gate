import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, Cell, ResponsiveContainer 
} from 'recharts';
import { 
  Code, FileCode, Play, LogOut, Database, Calendar, ShieldAlert, 
  Clock, User, RefreshCw, AlertTriangle, AlertCircle, Info, ChevronRight, FileJson
} from 'lucide-react';

function Dashboard({ user, setUser }) {
  const navigate = useNavigate();
  const [code, setCode] = useState('');
  const [filename, setFilename] = useState('sample-vulnerable.js');
  const [scanning, setScanning] = useState(false);
  const [scanHistory, setScanHistory] = useState([]);
  const [currentResult, setCurrentResult] = useState(null);
  const [activeTab, setActiveTab] = useState('summary'); // summary | details | payload

  // YOUR LAMBDA FUNCTION URL (fully configured and validated)
  const LAMBDA_URL = process.env.REACT_APP_API_URL;

  // Load scan history from localStorage on mount
  useEffect(() => {
    try {
      const history = localStorage.getItem(`${user.email}_scanHistory`);
      if (history) {
        setScanHistory(JSON.parse(history));
      }
    } catch (e) {
      console.error("Failed to load scan history", e);
    }
  }, [user.email]);

  // Save scan history to localStorage
  const saveToHistory = (result) => {
    const newHistory = [result, ...scanHistory].slice(0, 15); // Keep last 15 scans
    setScanHistory(newHistory);
    localStorage.setItem(`${user.email}_scanHistory`, JSON.stringify(newHistory));
  };

  const handleLogout = () => {
    localStorage.removeItem('user');
    setUser(null);
    navigate('/');
  };

  const loadSample = () => {
    setCode(`// Sample vulnerable JavaScript code
const stripe_secret = "sk_live_51NzABC1234567890abcdef1234567890";
const db_password = "super-secret-pass-99";

function authenticateUser(req, res) {
    const username = req.body.username;
    const password = req.body.password;
    
    // SQL Injection Vulnerability: String Concatenation in Query
    const sqlQuery = "SELECT * FROM users WHERE user = '" + username + "' AND pass = '" + password + "'";
    
    db.query(sqlQuery, (err, result) => {
        // ... authentication logic
    });
}

// Insecure eval usage (remote code execution risk)
const userPayload = req.query.payload;
eval(userPayload);

// Weak hash usage
const md5Hash = crypto.createHash('md5').update("data").digest('hex');

// Hardcoded IP Addresses
const server_ip = "192.168.1.254";

// TODO: Fix security review findings before deploying to production
`);
    setFilename('sample-vulnerable.js');
  };

  const scanCode = async () => {
    if (!code.trim()) {
      alert('Please enter or load some JavaScript code to scan');
      return;
    }

    setScanning(true);
    setCurrentResult(null);
    setActiveTab('summary');

    try {
      const response = await fetch(LAMBDA_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code: code, filename: filename })
      });

      if (!response.ok) {
        throw new Error(`HTTP Error Status: ${response.status}`);
      }

      const data = await response.json();

      if (data.success) {
        const result = {
          scanId: data.scanId,
          scannedAt: data.scannedAt,
          filename: filename,
          summary: data.summary,
          // If vulnerabilities list isn't returned, default to empty array
          vulnerabilities: data.vulnerabilities || [],
          s3Key: data.s3Key,
          rawCode: code
        };
        setCurrentResult(result);
        saveToHistory(result);
      } else {
        alert(`Error: ${data.error || 'Scan failed'}`);
      }
    } catch (error) {
      alert(`Network error calling AWS Lambda Function URL: ${error.message}`);
    } finally {
      setScanning(false);
    }
  };

  // Prepare chart data from current result
  const getCurrentChartData = () => {
    if (currentResult) {
      const s = currentResult.summary;
      return [
        { name: 'High', count: s.high, color: '#f43f5e' },
        { name: 'Medium', count: s.medium, color: '#f59e0b' },
        { name: 'Low', count: s.low, color: '#10b981' },
      ];
    }
    return [];
  };

  // Aggregate history data for trend chart
  const getTrendData = () => {
    const last5 = scanHistory.slice(0, 5).reverse();
    return last5.map((scan, idx) => ({
      scan: `Scan #${idx + 1}`,
      High: scan.summary.high,
      Medium: scan.summary.medium,
      Low: scan.summary.low,
    }));
  };

  const getSeverityColor = (severity) => {
    switch (severity.toUpperCase()) {
      case 'HIGH': return '#f43f5e';
      case 'MEDIUM': return '#f59e0b';
      case 'LOW': return '#10b981';
      default: return '#94a3b8';
    }
  };

  const clearHistory = () => {
    if (window.confirm("Are you sure you want to clear your local scan history?")) {
      setScanHistory([]);
      localStorage.removeItem(`${user.email}_scanHistory`);
    }
  };

  return (
    <div style={styles.container}>
      {/* Navbar Section */}
      <header style={styles.navbar}>
        <div style={styles.navLeft}>
          <div style={styles.navLogo}>
            <ShieldAlert size={20} color="#f8fafc" />
          </div>
          <div>
            <h1 style={styles.navTitle}>Startup Code Security Gate</h1>
            <p style={styles.navSubtitle}>Cloud Pipeline Dashboard — Group 9</p>
          </div>
        </div>
        <div style={styles.navRight}>
          <div style={styles.userProfile}>
            <div style={styles.avatar}>
              <User size={16} color="#6366f1" />
            </div>
            <div style={styles.userDetails}>
              <span style={styles.userName}>{user?.name}</span>
              <span style={styles.userEmail}>{user?.email}</span>
            </div>
          </div>
          <button onClick={handleLogout} style={styles.logoutButton}>
            <LogOut size={16} style={{ marginRight: '6px' }} />
            Logout
          </button>
        </div>
      </header>

      {/* Main Workspace */}
      <div style={styles.workspace}>
        {/* Left Column: Code Console Editor & Scan Control */}
        <section style={styles.leftCol}>
          <div style={styles.card}>
            <div style={styles.cardHeader}>
              <div style={styles.headerTitleGroup}>
                <Code size={18} color="#6366f1" />
                <h2 style={styles.cardTitle}>Scanner Workspace Console</h2>
              </div>
              <button onClick={loadSample} style={styles.sampleButton}>
                Load Vulnerable Sample
              </button>
            </div>

            <div style={styles.formGroup}>
              <label style={styles.inputLabel}>Target Filename</label>
              <div style={styles.filenameWrapper}>
                <FileCode size={16} color="#64748b" style={styles.filenameIcon} />
                <input
                  type="text"
                  value={filename}
                  onChange={(e) => setFilename(e.target.value)}
                  style={styles.input}
                  placeholder="e.g. app.js"
                />
              </div>
            </div>

            <div style={styles.formGroup}>
              <label style={styles.inputLabel}>JavaScript Source Code</label>
              <textarea
                value={code}
                onChange={(e) => setCode(e.target.value)}
                style={styles.codeArea}
                placeholder="// Paste or edit your JavaScript code here for vulnerability checks..."
              />
            </div>

            <button 
              onClick={scanCode} 
              disabled={scanning} 
              style={scanning ? {...styles.scanButton, opacity: 0.8} : styles.scanButton}
            >
              {scanning ? (
                <>
                  <RefreshCw size={18} className="pulse" style={{ marginRight: '8px', animation: 'spin 2s linear infinite' }} />
                  Running Code Analysis on AWS Lambda...
                </>
              ) : (
                <>
                  <Play size={18} style={{ marginRight: '8px' }} />
                  Start Security Scan
                </>
              )}
            </button>
          </div>

          {/* Scan Results Card */}
          {currentResult && (
            <div style={{...styles.card, marginTop: '24px'}}>
              <div style={styles.tabHeader}>
                <button 
                  onClick={() => setActiveTab('summary')}
                  style={activeTab === 'summary' ? {...styles.tabButton, ...styles.activeTab} : styles.tabButton}
                >
                  Scan Summary
                </button>
                <button 
                  onClick={() => setActiveTab('details')}
                  style={activeTab === 'details' ? {...styles.tabButton, ...styles.activeTab} : styles.tabButton}
                >
                  Detected Flaws ({currentResult.summary.totalVulnerabilities})
                </button>
                <button 
                  onClick={() => setActiveTab('payload')}
                  style={activeTab === 'payload' ? {...styles.tabButton, ...styles.activeTab} : styles.tabButton}
                >
                  S3 Metadata
                </button>
              </div>

              {activeTab === 'summary' && (
                <div style={styles.tabContent} className="animate-fade-in">
                  <div style={styles.metaGrid}>
                    <div style={styles.metaItem}>
                      <span style={styles.metaLabel}>Scan Reference ID</span>
                      <span style={styles.metaValue}>{currentResult.scanId}</span>
                    </div>
                    <div style={styles.metaItem}>
                      <span style={styles.metaLabel}>File Analyzed</span>
                      <span style={styles.metaValue}>{currentResult.filename}</span>
                    </div>
                    <div style={styles.metaItem}>
                      <span style={styles.metaLabel}>Timestamp</span>
                      <span style={styles.metaValue}>{new Date(currentResult.scannedAt).toLocaleTimeString()}</span>
                    </div>
                    <div style={styles.metaItem}>
                      <span style={styles.metaLabel}>Status</span>
                      <span style={{...styles.metaValue, color: '#10b981'}}>Success</span>
                    </div>
                  </div>

                  <div style={styles.divider}></div>

                  <div style={styles.summaryOverview}>
                    <div style={styles.overviewTotalBox}>
                      <span style={styles.totalCount}>{currentResult.summary.totalVulnerabilities}</span>
                      <span style={styles.totalLabel}>Vulnerabilities Found</span>
                    </div>
                    <div style={styles.overviewBreakdown}>
                      <div style={{...styles.breakdownRow, borderColor: '#f43f5e'}}>
                        <div style={{...styles.badgeDot, background: '#f43f5e'}}></div>
                        <span style={styles.breakdownLabel}>High Severity Risk</span>
                        <span style={styles.breakdownVal}>{currentResult.summary.high}</span>
                      </div>
                      <div style={{...styles.breakdownRow, borderColor: '#f59e0b'}}>
                        <div style={{...styles.badgeDot, background: '#f59e0b'}}></div>
                        <span style={styles.breakdownLabel}>Medium Severity Risk</span>
                        <span style={styles.breakdownVal}>{currentResult.summary.medium}</span>
                      </div>
                      <div style={{...styles.breakdownRow, borderColor: '#10b981'}}>
                        <div style={{...styles.badgeDot, background: '#10b981'}}></div>
                        <span style={styles.breakdownLabel}>Low Severity Risk</span>
                        <span style={styles.breakdownVal}>{currentResult.summary.low}</span>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {activeTab === 'details' && (
                <div style={styles.tabContent} className="animate-fade-in">
                  {currentResult.vulnerabilities.length === 0 ? (
                    <div style={styles.cleanReportBox}>
                      <div style={{...styles.badgeDot, background: '#10b981', width: '20px', height: '20px', marginBottom: '8px'}}></div>
                      <h3>No Flaws Detected!</h3>
                      <p>Your code is structurally sound according to current regex rules.</p>
                    </div>
                  ) : (
                    <div style={styles.vulnList}>
                      {currentResult.vulnerabilities.map((vuln, index) => (
                        <div key={index} style={styles.vulnCard}>
                          <div style={styles.vulnHeader}>
                            <div style={styles.vulnTitleGroup}>
                              <span style={{...styles.vulnBadge, background: getSeverityColor(vuln.severity)}}>
                                {vuln.severity}
                              </span>
                              <h4 style={styles.vulnName}>{vuln.name}</h4>
                            </div>
                            <span style={styles.vulnLine}>Line {vuln.line}</span>
                          </div>
                          <p style={styles.vulnDesc}>{vuln.message}</p>
                          <div style={styles.vulnEvidence}>
                            <code style={styles.evidenceCode}>{vuln.evidence}</code>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {activeTab === 'payload' && (
                <div style={styles.tabContent} className="animate-fade-in">
                  <div style={styles.metaGrid}>
                    <div style={styles.metaItem}>
                      <span style={styles.metaLabel}>S3 Storage Key</span>
                      <span style={styles.metaValue}><Database size={13} style={{ marginRight: '6px' }} /> {currentResult.s3Key}</span>
                    </div>
                    <div style={styles.metaItem}>
                      <span style={styles.metaLabel}>TTL (DynamoDB expiry)</span>
                      <span style={styles.metaValue}><Clock size={13} style={{ marginRight: '6px' }} /> 30-Day Auto Delete</span>
                    </div>
                  </div>
                  <div style={styles.s3InfoBox}>
                    <FileJson size={20} color="#6366f1" style={{ marginRight: '12px' }} />
                    <p style={styles.s3Text}>Full vulnerability report JSON payload successfully structured and uploaded to S3 bucket. Metadata indexed inside AWS DynamoDB.</p>
                  </div>
                </div>
              )}
            </div>
          )}
        </section>

        {/* Right Column: Visual Charts, Metrics & Scan History Log */}
        <section style={styles.rightCol}>
          {/* Active Scan Chart Card */}
          {currentResult && (
            <div style={styles.card} className="animate-fade-in">
              <div style={styles.cardHeader}>
                <div style={styles.headerTitleGroup}>
                  <Database size={18} color="#a855f7" />
                  <h2 style={styles.cardTitle}>Vulnerability Severity Breakdown</h2>
                </div>
              </div>
              <div style={styles.chartContainer}>
                <ResponsiveContainer width="100%" height={230}>
                  <BarChart data={getCurrentChartData()} margin={{ top: 10, right: 10, left: -25, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                    <XAxis dataKey="name" stroke="#94a3b8" />
                    <YAxis stroke="#94a3b8" allowDecimals={false} />
                    <Tooltip 
                      contentStyle={{ background: '#1e293b', borderColor: '#334155', borderRadius: '8px' }}
                      labelStyle={{ color: '#f8fafc' }}
                    />
                    <Bar dataKey="count" radius={[4, 4, 0, 0]}>
                      {getCurrentChartData().map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          )}

          {/* Historical Trend Chart Card */}
          {getTrendData().length > 0 && (
            <div style={styles.card}>
              <div style={styles.cardHeader}>
                <div style={styles.headerTitleGroup}>
                  <Calendar size={18} color="#10b981" />
                  <h2 style={styles.cardTitle}>Vulnerability Trends (Last {getTrendData().length} Scans)</h2>
                </div>
              </div>
              <div style={styles.chartContainer}>
                <ResponsiveContainer width="100%" height={230}>
                  <BarChart data={getTrendData()} margin={{ top: 10, right: 10, left: -25, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                    <XAxis dataKey="scan" stroke="#94a3b8" />
                    <YAxis stroke="#94a3b8" allowDecimals={false} />
                    <Tooltip 
                      contentStyle={{ background: '#1e293b', borderColor: '#334155', borderRadius: '8px' }}
                      labelStyle={{ color: '#f8fafc' }}
                    />
                    <Legend verticalAlign="top" height={36} iconType="circle" />
                    <Bar dataKey="High" fill="#f43f5e" radius={[2, 2, 0, 0]} />
                    <Bar dataKey="Medium" fill="#f59e0b" radius={[2, 2, 0, 0]} />
                    <Bar dataKey="Low" fill="#10b981" radius={[2, 2, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          )}

          {/* Scan Log History Table/List */}
          <div style={styles.card}>
            <div style={styles.cardHeader}>
              <div style={styles.headerTitleGroup}>
                <Clock size={18} color="#64748b" />
                <h2 style={styles.cardTitle}>Recent Security Audits</h2>
              </div>
              {scanHistory.length > 0 && (
                <button onClick={clearHistory} style={styles.clearHistoryButton}>
                  Clear Log
                </button>
              )}
            </div>
            {scanHistory.length === 0 ? (
              <div style={styles.emptyHistoryBox}>
                <Database size={24} color="#334155" style={{ marginBottom: '8px' }} />
                <p style={styles.emptyHistoryText}>No scans logged for this session yet.</p>
              </div>
            ) : (
              <div style={styles.historyList}>
                {scanHistory.map((scan, idx) => (
                  <div key={idx} style={styles.historyItem} onClick={() => setCurrentResult(scan)}>
                    <div style={styles.historyMeta}>
                      <div style={{ display: 'flex', alignItems: 'center' }}>
                        <ChevronRight size={14} color="#6366f1" style={{ marginRight: '6px' }} />
                        <span style={styles.historyFilename}>{scan.filename}</span>
                      </div>
                      <span style={styles.historyTime}>{new Date(scan.scannedAt).toLocaleDateString()} {new Date(scan.scannedAt).toLocaleTimeString()}</span>
                    </div>
                    <div style={styles.historyCounts}>
                      <span style={styles.countBadge}><AlertCircle size={11} style={{ marginRight: '4px' }} /> H: {scan.summary.high}</span>
                      <span style={styles.countBadge}><AlertTriangle size={11} style={{ marginRight: '4px' }} /> M: {scan.summary.medium}</span>
                      <span style={styles.countBadge}><Info size={11} style={{ marginRight: '4px' }} /> L: {scan.summary.low}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </section>
      </div>
    </div>
  );
}

const styles = {
  container: {
    minHeight: '100vh',
    background: '#0f172a',
    display: 'flex',
    flexDirection: 'column',
  },
  navbar: {
    background: '#1e293b',
    borderBottom: '1px solid #334155',
    padding: '16px 32px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  navLeft: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
  },
  navLogo: {
    background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
    width: '40px',
    height: '40px',
    borderRadius: '10px',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    boxShadow: '0 8px 16px -4px rgba(99, 102, 241, 0.3)',
  },
  navTitle: {
    fontSize: '16px',
    fontWeight: '700',
    color: '#f8fafc',
    lineHeight: '1.2',
  },
  navSubtitle: {
    fontSize: '11px',
    color: '#94a3b8',
    fontWeight: '500',
  },
  navRight: {
    display: 'flex',
    alignItems: 'center',
    gap: '24px',
  },
  userProfile: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
  },
  avatar: {
    background: '#0f172a',
    border: '1px solid #334155',
    width: '32px',
    height: '32px',
    borderRadius: '50%',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
  },
  userDetails: {
    display: 'flex',
    flexDirection: 'column',
  },
  userName: {
    fontSize: '13px',
    fontWeight: '600',
    color: '#f8fafc',
    lineHeight: '1.2',
  },
  userEmail: {
    fontSize: '11px',
    color: '#64748b',
  },
  logoutButton: {
    background: 'none',
    border: '1px solid #334155',
    color: '#94a3b8',
    padding: '8px 14px',
    borderRadius: '8px',
    fontSize: '13px',
    fontWeight: '500',
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    transition: 'all 0.15s ease',
  },
  workspace: {
    display: 'flex',
    gap: '24px',
    padding: '32px',
    flex: '1',
    maxWidth: '1440px',
    width: '100%',
    margin: '0 auto',
  },
  leftCol: {
    flex: '1.2',
    display: 'flex',
    flexDirection: 'column',
    minWidth: '0',
  },
  rightCol: {
    flex: '0.8',
    display: 'flex',
    flexDirection: 'column',
    gap: '24px',
    minWidth: '0',
  },
  card: {
    background: '#1e293b',
    border: '1px solid #334155',
    borderRadius: '12px',
    padding: '24px',
    boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
  },
  cardHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '20px',
  },
  headerTitleGroup: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
  },
  cardTitle: {
    fontSize: '15px',
    fontWeight: '600',
    color: '#f8fafc',
  },
  sampleButton: {
    background: 'rgba(99, 102, 241, 0.1)',
    border: '1px solid rgba(99, 102, 241, 0.2)',
    color: '#818cf8',
    padding: '6px 12px',
    borderRadius: '6px',
    fontSize: '12px',
    fontWeight: '600',
    cursor: 'pointer',
    transition: 'all 0.15s ease',
  },
  formGroup: {
    marginBottom: '16px',
  },
  inputLabel: {
    display: 'block',
    fontSize: '11px',
    fontWeight: '600',
    color: '#94a3b8',
    textTransform: 'uppercase',
    letterSpacing: '0.05em',
    marginBottom: '6px',
  },
  filenameWrapper: {
    position: 'relative',
    display: 'flex',
    alignItems: 'center',
  },
  filenameIcon: {
    position: 'absolute',
    left: '12px',
  },
  input: {
    width: '100%',
    padding: '10px 12px 10px 36px',
    background: '#0f172a',
    border: '1px solid #334155',
    borderRadius: '8px',
    color: '#f8fafc',
    fontSize: '14px',
    outline: 'none',
    fontFamily: 'inherit',
  },
  codeArea: {
    width: '100%',
    height: '280px',
    padding: '16px',
    background: '#0b0f19',
    border: '1px solid #334155',
    borderRadius: '8px',
    color: '#e2e8f0',
    fontFamily: 'var(--font-mono)',
    fontSize: '12px',
    lineHeight: '1.6',
    outline: 'none',
    resize: 'vertical',
  },
  scanButton: {
    width: '100%',
    padding: '14px',
    background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
    color: 'white',
    border: 'none',
    borderRadius: '8px',
    fontSize: '14px',
    fontWeight: '600',
    cursor: 'pointer',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    boxShadow: '0 4px 12px rgba(99, 102, 241, 0.3)',
  },
  tabHeader: {
    display: 'flex',
    borderBottom: '1px solid #334155',
    gap: '16px',
    marginBottom: '20px',
  },
  tabButton: {
    background: 'none',
    border: 'none',
    color: '#64748b',
    padding: '8px 4px 12px 4px',
    fontSize: '14px',
    fontWeight: '600',
    cursor: 'pointer',
    position: 'relative',
    transition: 'color 0.15s ease',
  },
  activeTab: {
    color: '#6366f1',
    borderBottom: '2px solid #6366f1',
  },
  tabContent: {
    minHeight: '180px',
  },
  metaGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(2, 1fr)',
    gap: '16px',
  },
  metaItem: {
    display: 'flex',
    flexDirection: 'column',
    gap: '4px',
  },
  metaLabel: {
    fontSize: '11px',
    color: '#64748b',
    textTransform: 'uppercase',
    fontWeight: '600',
  },
  metaValue: {
    fontSize: '13px',
    fontWeight: '500',
    color: '#cbd5e1',
    wordBreak: 'break-all',
  },
  divider: {
    height: '1px',
    background: '#334155',
    margin: '20px 0',
  },
  summaryOverview: {
    display: 'flex',
    alignItems: 'center',
    gap: '40px',
  },
  overviewTotalBox: {
    background: 'rgba(99, 102, 241, 0.05)',
    border: '1px solid rgba(99, 102, 241, 0.15)',
    borderRadius: '12px',
    padding: '16px 24px',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    minWidth: '150px',
  },
  totalCount: {
    fontSize: '36px',
    fontWeight: '800',
    color: '#cbd5e1',
  },
  totalLabel: {
    fontSize: '11px',
    color: '#94a3b8',
    fontWeight: '600',
    textAlign: 'center',
  },
  overviewBreakdown: {
    flex: '1',
    display: 'flex',
    flexDirection: 'column',
    gap: '10px',
  },
  breakdownRow: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '8px 16px',
    background: '#0f172a',
    borderRadius: '8px',
    borderLeft: '4px solid transparent',
  },
  badgeDot: {
    width: '8px',
    height: '8px',
    borderRadius: '50%',
    marginRight: '12px',
  },
  breakdownLabel: {
    fontSize: '13px',
    color: '#94a3b8',
    flex: '1',
  },
  breakdownVal: {
    fontSize: '14px',
    fontWeight: '700',
    color: '#cbd5e1',
  },
  vulnList: {
    display: 'flex',
    flexDirection: 'column',
    gap: '14px',
    maxHeight: '380px',
    overflowY: 'auto',
    paddingRight: '4px',
  },
  vulnCard: {
    background: '#0f172a',
    border: '1px solid #334155',
    borderRadius: '8px',
    padding: '14px',
  },
  vulnHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '8px',
  },
  vulnTitleGroup: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
  },
  vulnBadge: {
    padding: '2px 8px',
    borderRadius: '4px',
    color: '#0f172a',
    fontSize: '10px',
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  vulnName: {
    fontSize: '13px',
    fontWeight: '600',
    color: '#f8fafc',
  },
  vulnLine: {
    fontSize: '11px',
    color: '#64748b',
    fontWeight: '500',
  },
  vulnDesc: {
    fontSize: '12px',
    color: '#94a3b8',
    marginBottom: '10px',
    lineHeight: '1.4',
  },
  vulnEvidence: {
    background: '#0b0f19',
    border: '1px solid #1e293b',
    borderRadius: '6px',
    padding: '10px',
    overflowX: 'auto',
  },
  evidenceCode: {
    fontFamily: 'var(--font-mono)',
    fontSize: '11px',
    color: '#f43f5e',
    whiteSpace: 'pre',
  },
  s3InfoBox: {
    display: 'flex',
    alignItems: 'center',
    padding: '16px',
    background: 'rgba(99, 102, 241, 0.05)',
    border: '1px solid rgba(99, 102, 241, 0.15)',
    borderRadius: '8px',
    marginTop: '24px',
  },
  s3Text: {
    fontSize: '12px',
    color: '#cbd5e1',
    lineHeight: '1.5',
  },
  cleanReportBox: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: '160px',
    color: '#94a3b8',
  },
  chartContainer: {
    marginTop: '10px',
    background: '#0f172a',
    padding: '16px',
    borderRadius: '8px',
    border: '1px solid #1e293b',
  },
  clearHistoryButton: {
    background: 'none',
    border: 'none',
    color: '#f43f5e',
    fontSize: '12px',
    fontWeight: '500',
    cursor: 'pointer',
  },
  emptyHistoryBox: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: '120px',
  },
  emptyHistoryText: {
    fontSize: '12px',
    color: '#64748b',
  },
  historyList: {
    display: 'flex',
    flexDirection: 'column',
    gap: '10px',
    maxHeight: '260px',
    overflowY: 'auto',
    paddingRight: '4px',
  },
  historyItem: {
    background: '#0f172a',
    border: '1px solid #1e293b',
    borderRadius: '8px',
    padding: '10px 14px',
    cursor: 'pointer',
    transition: 'all 0.15s ease',
    display: 'flex',
    flexDirection: 'column',
    gap: '6px',
  },
  historyMeta: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  historyFilename: {
    fontSize: '12px',
    fontWeight: '600',
    color: '#cbd5e1',
  },
  historyTime: {
    fontSize: '10px',
    color: '#64748b',
  },
  historyCounts: {
    display: 'flex',
    gap: '12px',
  },
  countBadge: {
    fontSize: '10px',
    color: '#94a3b8',
    display: 'flex',
    alignItems: 'center',
  }
};

export default Dashboard;
