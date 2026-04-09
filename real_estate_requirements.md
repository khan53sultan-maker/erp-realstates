# Real Estate Commission & Sales Management Software Requirements

## Project Info
**Client:** Iconic Estate (A Sign of Trust)
**Purpose:** Management of real estate projects, plot sales, commissions, and dealer payouts.

---

## 1. Business Logic & Overview
Iconic Estate markets and sells plots for various landowners (e.g., Umar Homes, JS Lodges).
- **Landowner Commission:** 12% (default, editable) from the landowner.
- **Basis of Calculation:** Commission is calculated on the **30% Down Payment** of the plot value.
- **Dealer Payout:** 5% (default, editable) paid to the team member/dealer from the company's commission (or configurable based on plot price).
- **Profit:** Remaining amount after dealer payout is company profit.

---

## 2. Core Modules

### A. Project Management
- **Fields:** Project Name, Location, Landowner Name, Total Plots, Plot Sizes (5 Marla, 10 Marla, 1 Kanal, etc.).
- **Configurations:** Commission % from landowner, Down payment %, Payment plan details.
- **Status:** Active / Closed.

### B. Plot Management
- **Fields:** Plot Number, Plot Size, Total Price.
- **Status:** Available, Reserved, Sold.
- **Tracking:** Linked to Client, Sale Date, and Sales Person/Dealer (when sold).

### C. Client Management (CRM)
- **Data:** Full Name, Father Name, CNIC, Phone, WhatsApp, Address.
- **Linkage:** Project Name, Plot Number, Total Price, Down Payment.
- **Financials:** Installment Plan, Payment History, Remaining Balance.
- **Features:** Search & Filter, Document Upload (Future).

### D. Sales & Commission Automation
- **Trigger:** When plot status changes to **SOLD**.
- **Automated Calculations:**
  1. `Landowner Commission = (Down Payment Amount) * (Commission %)`
  2. `Dealer Commission = Configurable % (e.g., 5% of plot price or % of landowner commission)`
  3. `Net Company Profit = Landowner Commission - Dealer Commission`
- **Commission Management:** Pending, Paid, Partially Paid status.

### E. Dealer / Team Management
- **Data:** Name, Phone, Default Commission %, Total Sales, Commission Earned, Paid/Pending amounts.
- **Dashboard:** Separate performance view for dealers.

### F. Income & Expense Module
- **Income:** Commission Received, Other income.
- **Expenses:** Rent, Salaries, Marketing, Utilities, Misc.
- **Reports:** Daily, Weekly, Monthly, Project-wise profit.

### G. Dashboard
- **KPIs:** Total Sales (Project-wise), Total Commission Received, Paid to Dealers, Net Profit, Pending Commissions, Available Plots.
- **Visuals:** Monthly sales graph, Income vs Expense graph, Dealer performance graph.

### H. Reports (Export to PDF/Excel)
- Sales Report (Date range).
- Project-wise commission report.
- Dealer commission report.
- Client payment report.
- Profit & Loss report.
- Daily cash flow.

### I. User Roles & Security
- **Admin:** Full access.
- **Manager:** Limited management access.
- **Sales Agent:** Lead/Sale entry access.
- **Accountant:** Financial data access.
