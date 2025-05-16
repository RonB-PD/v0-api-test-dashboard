"use client"

import { useState } from "react"
import {
  CalendarIcon,
  CheckCircle2,
  ChevronDown,
  Clock,
  Download,
  Filter,
  RefreshCw,
  Search,
  XCircle,
} from "lucide-react"
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

// Mock data for API test results
const mockTestResults = [
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
  const [selectedTest, setSelectedTest] = useState<any | null>(null)
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
  const handleRowClick = (test: any) => {
    setSelectedTest(test)
    setIsDetailOpen(true)
  }

  // Stats calculation
  const totalTests = mockTestResults.length
  const passedTests = mockTestResults.filter((test) => test.status === "passed").length
  const failedTests = mockTestResults.filter((test) => test.status === "failed").length
  const pendingTests = mockTestResults.filter((test) => test.status === "pending").length
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
