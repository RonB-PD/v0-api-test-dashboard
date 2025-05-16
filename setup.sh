#!/bin/bash

# API Test Dashboard Setup Script
# This script will:
# 1. Install necessary dependencies (Node.js, npm, Nginx)
# 2. Create the project directory and files
# 3. Set up the Next.js application
# 4. Configure Nginx as a reverse proxy
# 5. Set up the app to run as a service
# 6. Start all services

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Log function
log() {
  echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
  echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
  exit 1
}

warning() {
  echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  error "Please run as root (use sudo)"
fi

# Configuration variables
APP_NAME="api-test-dashboard"
APP_DIR="/var/www/$APP_NAME"
APP_PORT=3000
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"
NODE_VERSION="20.x"

log "Starting setup for $APP_NAME..."

# Step 1: Update system and install dependencies
log "Updating system packages..."
apt update || error "Failed to update system packages"

log "Installing required packages..."
apt install -y curl git nginx || error "Failed to install required packages"

# Install Node.js
if ! command -v node &> /dev/null; then
  log "Installing Node.js $NODE_VERSION..."
  curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - || error "Failed to set up Node.js repository"
  apt install -y nodejs || error "Failed to install Node.js"
  log "Node.js $(node -v) installed successfully"
else
  log "Node.js $(node -v) is already installed"
fi

# Step 2: Create project directory
log "Creating project directory at $APP_DIR..."
mkdir -p $APP_DIR || error "Failed to create project directory"

# Step 3: Clone or create the application
log "Setting up the application..."

# Create a new Next.js app
cd $APP_DIR || error "Failed to change to app directory"
log "Initializing Next.js application..."
npx create-next-app@latest . --typescript --eslint --tailwind --app --src-dir --use-npm --no-git || error "Failed to create Next.js app"

# Install additional dependencies
log "Installing additional dependencies..."
npm install date-fns lucide-react || error "Failed to install additional dependencies"

# Install shadcn/ui components
log "Setting up shadcn/ui components..."
npx shadcn@latest init --yes || error "Failed to initialize shadcn/ui"
npx shadcn@latest add button card input select table badge dropdown-menu popover calendar dialog tabs || error "Failed to add shadcn/ui components"

# Step 4: Create application files
log "Creating application files..."

# Create the components directory if it doesn't exist
mkdir -p $APP_DIR/src/components

# Create .eslintrc.json to disable the no-explicit-any rule
cat > $APP_DIR/.eslintrc.json << 'EOF'
{
  "extends": "next/core-web-vitals",
  "rules": {
    "@typescript-eslint/no-explicit-any": "off",
    "@typescript-eslint/no-unused-vars": "warn"
  }
}
EOF

# Create the API test dashboard component
cat > $APP_DIR/src/components/api-test-dashboard.tsx << 'EOF'
"use client"

import { useState } from "react"
import { CalendarIcon, CheckCircle2, ChevronDown, Clock, Download, Filter, RefreshCw, Search, XCircle } from 'lucide-react'
import { format } from "date-fns"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Badge } from "@/components/ui/badge"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import { Calendar } from "@/components/ui/calendar"
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

// Define types for our test results
interface TestResult {
  id: string
  endpoint: string
  method: string
  status: "passed" | "failed" | "pending"
  responseTime: number | null
  timestamp: Date
  statusCode: number | null
  requestPayload: Record<string, unknown>
  responsePayload: Record<string, unknown> | null
}

// Mock data for API test results
const mockTestResults: TestResult[] = [
  {
    id: "test-001",
    endpoint: "/api/users",
    method: "GET",
    status: "passed",
    responseTime: 120,
    timestamp: new Date(2023, 4, 15, 10, 30),
    statusCode: 200,
    requestPayload: { page: 1, limit: 10 },
    responsePayload: { users: [], total: 0 },
  },
  {
    id: "test-002",
    endpoint: "/api/products",
    method: "POST",
    status: "failed",
    responseTime: 350,
    timestamp: new Date(2023, 4, 15, 11, 45),
    statusCode: 500,
    requestPayload: { name: "New Product", price: 99.99 },
    responsePayload: { error: "Internal Server Error" },
  },
  {
    id: "test-003",
    endpoint: "/api/auth/login",
    method: "POST",
    status: "passed",
    responseTime: 200,
    timestamp: new Date(2023, 4, 15, 12, 15),
    statusCode: 200,
    requestPayload: { username: "user", password: "****" },
    responsePayload: { token: "jwt-token" },
  },
  {
    id: "test-004",
    endpoint: "/api/orders",
    method: "GET",
    status: "pending",
    responseTime: null,
    timestamp: new Date(2023, 4, 15, 13, 0),
    statusCode: null,
    requestPayload: { status: "processing" },
    responsePayload: null,
  },
  {
    id: "test-005",
    endpoint: "/api/products/1",
    method: "PUT",
    status: "passed",
    responseTime: 180,
    timestamp: new Date(2023, 4, 16, 9, 30),
    statusCode: 200,
    requestPayload: { price: 129.99 },
    responsePayload: { id: 1, name: "Product 1", price: 129.99 },
  },
  {
    id: "test-006",
    endpoint: "/api/products/2",
    method: "DELETE",
    status: "failed",
    responseTime: 300,
    timestamp: new Date(2023, 4, 16, 10, 15),
    statusCode: 403,
    requestPayload: {},
    responsePayload: { error: "Permission denied" },
  },
  {
    id: "test-007",
    endpoint: "/api/users/profile",
    method: "GET",
    status: "passed",
    responseTime: 150,
    timestamp: new Date(2023, 4, 16, 11, 0),
    statusCode: 200,
    requestPayload: {},
    responsePayload: { id: 1, name: "John Doe", email: "john@example.com" },
  },
  {
    id: "test-008",
    endpoint: "/api/webhooks",
    method: "POST",
    status: "pending",
    responseTime: null,
    timestamp: new Date(2023, 4, 16, 12, 30),
    statusCode: null,
    requestPayload: { event: "order.created", data: {} },
    responsePayload: null,
  },
]

// Status badge component
const StatusBadge = ({ status }: { status: string }) => {
  if (status === "passed") {
    return (
      <Badge className="bg-green-100 text-green-800 hover:bg-green-100">
        <CheckCircle2 className="w-3.5 h-3.5 mr-1" />
        Passed
      </Badge>
    )
  } else if (status === "failed") {
    return (
      <Badge variant="destructive" className="bg-red-100 text-red-800 hover:bg-red-100">
        <XCircle className="w-3.5 h-3.5 mr-1" />
        Failed
      </Badge>
    )
  } else {
    return (
      <Badge variant="outline" className="bg-yellow-100 text-yellow-800 hover:bg-yellow-100">
        <Clock className="w-3.5 h-3.5 mr-1" />
        Pending
      </Badge>
    )
  }
}

export function ApiTestDashboard() {
  const [searchQuery, setSearchQuery] = useState("")
  const [statusFilter, setStatusFilter] = useState<string[]>([])
  const [methodFilter, setMethodFilter] = useState<string>("")
  const [date, setDate] = useState<Date | undefined>(undefined)
  const [selectedTest, setSelectedTest] = useState<TestResult | null>(null)
  const [isDetailOpen, setIsDetailOpen] = useState(false)

  // Filter the test results based on search query, status, method, and date
  const filteredResults = mockTestResults.filter((test) => {
    const matchesSearch = test.endpoint.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesStatus = statusFilter.length === 0 || statusFilter.includes(test.status)
    const matchesMethod = !methodFilter || test.method === methodFilter
    const matchesDate = !date || format(test.timestamp, "yyyy-MM-dd") === format(date, "yyyy-MM-dd")

    return matchesSearch && matchesStatus && matchesMethod && matchesDate
  })

  // Get unique methods for the filter dropdown
  const methods = Array.from(new Set(mockTestResults.map((test) => test.method)))

  // Handle row click to show details
  const handleRowClick = (test: TestResult) => {
    setSelectedTest(test)
    setIsDetailOpen(true)
  }

  // Stats calculation
  const totalTests = mockTestResults.length
  const passedTests = mockTestResults.filter((test) => test.status === "passed").length
  const failedTests = mockTestResults.filter((test) => test.status === "failed").length
  // We'll use pendingTests in a future update
  // const pendingTests = mockTestResults.filter((test) => test.status === "pending").length
  const avgResponseTime =
    mockTestResults
      .filter((test) => test.responseTime !== null)
      .reduce((sum, test) => sum + (test.responseTime || 0), 0) /
    mockTestResults.filter((test) => test.responseTime !== null).length

  return (
    <div className="flex flex-col min-h-screen bg-gray-50">
      <header className="border-b bg-white">
        <div className="container mx-auto py-4 px-4">
          <div className="flex justify-between items-center">
            <h1 className="text-2xl font-bold">API Test Results Dashboard</h1>
            <div className="flex items-center gap-2">
              <Button variant="outline" size="sm">
                <RefreshCw className="h-4 w-4 mr-2" />
                Refresh
              </Button>
              <Button variant="outline" size="sm">
                <Download className="h-4 w-4 mr-2" />
                Export
              </Button>
            </div>
          </div>
        </div>
      </header>

      <main className="flex-1 container mx-auto py-6 px-4">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Total Tests</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{totalTests}</div>
              <p className="text-xs text-muted-foreground">Last 24 hours</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Passed Tests</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">{passedTests}</div>
              <p className="text-xs text-muted-foreground">
                {Math.round((passedTests / totalTests) * 100)}% success rate
              </p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Failed Tests</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-red-600">{failedTests}</div>
              <p className="text-xs text-muted-foreground">
                {Math.round((failedTests / totalTests) * 100)}% failure rate
              </p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Avg. Response Time</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{Math.round(avgResponseTime)} ms</div>
              <p className="text-xs text-muted-foreground">Across all endpoints</p>
            </CardContent>
          </Card>
        </div>

        {/* Filters */}
        <Card className="mb-6">
          <CardHeader>
            <CardTitle>Filters</CardTitle>
            <CardDescription>Filter test results by various criteria</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="relative">
                <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  type="search"
                  placeholder="Search endpoints..."
                  className="pl-8"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>

              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" className="w-full justify-between">
                    <div className="flex items-center">
                      <Filter className="mr-2 h-4 w-4" />
                      {statusFilter.length === 0 ? "Status: All" : `Status: ${statusFilter.length} selected`}
                    </div>
                    <ChevronDown className="h-4 w-4 opacity-50" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent className="w-56">
                  <DropdownMenuCheckboxItem
                    checked={statusFilter.includes("passed")}
                    onCheckedChange={(checked) => {
                      if (checked) {
                        setStatusFilter([...statusFilter, "passed"])
                      } else {
                        setStatusFilter(statusFilter.filter((s) => s !== "passed"))
                      }
                    }}
                  >
                    Passed
                  </DropdownMenuCheckboxItem>
                  <DropdownMenuCheckboxItem
                    checked={statusFilter.includes("failed")}
                    onCheckedChange={(checked) => {
                      if (checked) {
                        setStatusFilter([...statusFilter, "failed"])
                      } else {
                        setStatusFilter(statusFilter.filter((s) => s !== "failed"))
                      }
                    }}
                  >
                    Failed
                  </DropdownMenuCheckboxItem>
                  <DropdownMenuCheckboxItem
                    checked={statusFilter.includes("pending")}
                    onCheckedChange={(checked) => {
                      if (checked) {
                        setStatusFilter([...statusFilter, "pending"])
                      } else {
                        setStatusFilter(statusFilter.filter((s) => s !== "pending"))
                      }
                    }}
                  >
                    Pending
                  </DropdownMenuCheckboxItem>
                </DropdownMenuContent>
              </DropdownMenu>

              <Select value={methodFilter} onValueChange={setMethodFilter}>
                <SelectTrigger>
                  <SelectValue placeholder="HTTP Method" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Methods</SelectItem>
                  {methods.map((method) => (
                    <SelectItem key={method} value={method}>
                      {method}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>

              <Popover>
                <PopoverTrigger asChild>
                  <Button variant="outline" className="w-full justify-start text-left font-normal">
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {date ? format(date, "PPP") : "Pick a date"}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0">
                  <Calendar mode="single" selected={date} onSelect={setDate} initialFocus />
                </PopoverContent>
              </Popover>
            </div>
          </CardContent>
        </Card>

        {/* Results Table */}
        <Card>
          <CardHeader>
            <CardTitle>Test Results</CardTitle>
            <CardDescription>
              Showing {filteredResults.length} of {totalTests} test results
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>ID</TableHead>
                  <TableHead>Endpoint</TableHead>
                  <TableHead>Method</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Response Time</TableHead>
                  <TableHead>Timestamp</TableHead>
                  <TableHead>Status Code</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredResults.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} className="text-center py-8 text-muted-foreground">
                      No test results match your filters
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredResults.map((test) => (
                    <TableRow
                      key={test.id}
                      className="cursor-pointer hover:bg-muted/50"
                      onClick={() => handleRowClick(test)}
                    >
                      <TableCell className="font-mono text-xs">{test.id}</TableCell>
                      <TableCell className="font-mono text-xs">{test.endpoint}</TableCell>
                      <TableCell>
                        <Badge variant="outline" className="font-mono">
                          {test.method}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <StatusBadge status={test.status} />
                      </TableCell>
                      <TableCell>{test.responseTime !== null ? `${test.responseTime} ms` : "-"}</TableCell>
                      <TableCell className="text-muted-foreground">
                        {format(test.timestamp, "MMM dd, yyyy HH:mm")}
                      </TableCell>
                      <TableCell className="font-mono">{test.statusCode !== null ? test.statusCode : "-"}</TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </main>

      {/* Test Details Dialog */}
      <Dialog open={isDetailOpen} onOpenChange={setIsDetailOpen}>
        <DialogContent className="max-w-3xl">
          <DialogHeader>
            <DialogTitle>Test Details: {selectedTest?.id}</DialogTitle>
            <DialogDescription>
              {selectedTest?.endpoint} - {selectedTest?.method}
            </DialogDescription>
          </DialogHeader>

          {selectedTest && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <StatusBadge status={selectedTest.status} />
                <div className="text-sm text-muted-foreground">
                  {format(selectedTest.timestamp, "PPP 'at' HH:mm:ss")}
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div className="space-y-1">
                  <h4 className="text-sm font-medium">Status Code</h4>
                  <p className="font-mono text-lg">
                    {selectedTest.statusCode !== null ? selectedTest.statusCode : "-"}
                  </p>
                </div>
                <div className="space-y-1">
                  <h4 className="text-sm font-medium">Response Time</h4>
                  <p className="font-mono text-lg">
                    {selectedTest.responseTime !== null ? `${selectedTest.responseTime} ms` : "-"}
                  </p>
                </div>
                <div className="space-y-1">
                  <h4 className="text-sm font-medium">Method</h4>
                  <p className="font-mono text-lg">{selectedTest.method}</p>
                </div>
              </div>

              <Tabs defaultValue="request">
                <TabsList className="grid w-full grid-cols-2">
                  <TabsTrigger value="request">Request</TabsTrigger>
                  <TabsTrigger value="response">Response</TabsTrigger>
                </TabsList>
                <TabsContent value="request" className="space-y-4">
                  <div className="rounded-md bg-muted p-4">
                    <h4 className="text-sm font-medium mb-2">Request Payload</h4>
                    <pre className="text-xs overflow-auto p-2 bg-slate-950 text-slate-50 rounded-md">
                      {JSON.stringify(selectedTest.requestPayload, null, 2)}
                    </pre>
                  </div>
                </TabsContent>
                <TabsContent value="response" className="space-y-4">
                  <div className="rounded-md bg-muted p-4">
                    <h4 className="text-sm font-medium mb-2">Response Payload</h4>
                    <pre className="text-xs overflow-auto p-2 bg-slate-950 text-slate-50 rounded-md">
                      {selectedTest.responsePayload
                        ? JSON.stringify(selectedTest.responsePayload, null, 2)
                        : "No response data available"}
                    </pre>
                  </div>
                </TabsContent>
              </Tabs>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}
EOF

# Create the page component
cat > $APP_DIR/src/app/page.tsx << 'EOF'
import { ApiTestDashboard } from "@/components/api-test-dashboard"

export default function Home() {
  return <ApiTestDashboard />
}
EOF

# Step 5: Build the application
log "Building the application..."
cd $APP_DIR || error "Failed to change to app directory"
npm run build || error "Failed to build the application"

# Step 6: Create systemd service file
log "Creating systemd service file..."
cat > /etc/systemd/system/$APP_NAME.service << EOF
[Unit]
Description=API Test Dashboard Next.js Application
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/npm start
Restart=on-failure
Environment=NODE_ENV=production
Environment=PORT=$APP_PORT

[Install]
WantedBy=multi-user.target
EOF

# Step 7: Configure Nginx
log "Configuring Nginx as a reverse proxy..."
cat > $NGINX_CONF << EOF
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/$APP_NAME-access.log;
    error_log /var/log/nginx/$APP_NAME-error.log;

    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Create symbolic link to enable the site
ln -sf $NGINX_CONF /etc/nginx/sites-enabled/ || error "Failed to enable Nginx site"

# Test Nginx configuration
nginx -t || error "Nginx configuration test failed"

# Step 8: Set permissions
log "Setting correct permissions..."
chown -R www-data:www-data $APP_DIR || error "Failed to set permissions"
chmod -R 755 $APP_DIR || error "Failed to set permissions"

# Step 9: Start and enable services
log "Starting and enabling services..."
systemctl daemon-reload || error "Failed to reload systemd"
systemctl enable $APP_NAME.service || error "Failed to enable app service"
systemctl start $APP_NAME.service || error "Failed to start app service"
systemctl restart nginx || error "Failed to restart Nginx"

# Step 10: Final message
IP_ADDRESS=$(hostname -I | awk '{print $1}')
log "Setup completed successfully!"
log "You can access your API Test Dashboard at: http://$IP_ADDRESS"
log "To check the status of the application, run: systemctl status $APP_NAME"
