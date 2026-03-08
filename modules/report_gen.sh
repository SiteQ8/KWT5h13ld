#!/usr/bin/env bash
run_report_gen() {
    local report_file="${REPORTS_DIR}/kwt5h13ld_report_${TIMESTAMP}.html"
    echo ""
    log INFO "═══════════════════════════════════════════════════════"
    log INFO "  GENERATING CONSOLIDATED SECURITY REPORT"
    log INFO "═══════════════════════════════════════════════════════"
    echo ""

    local existing_reports
    existing_reports=$(ls -1 "${REPORTS_DIR}"/*.txt 2>/dev/null)

    cat > "${report_file}" << HTMLEOF
<!DOCTYPE html>
<html>
<head>
<title>KWT5H13LD Security Report</title>
<style>
body { font-family: 'Segoe UI', Tahoma, sans-serif; background: #0a0e17; color: #c9d1d9; padding: 40px; }
h1 { color: #58a6ff; border-bottom: 2px solid #30363d; padding-bottom: 10px; }
h2 { color: #79c0ff; }
.report-section { background: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 20px; margin: 15px 0; }
.pass { color: #3fb950; } .fail { color: #f85149; } .warn { color: #d29922; }
pre { background: #0d1117; padding: 15px; border-radius: 6px; overflow-x: auto; }
.header { text-align: center; margin-bottom: 30px; }
.header img { width: 100px; }
</style>
</head>
<body>
<div class="header">
<h1>KWT5H13LD Security Report</h1>
<p>Generated: $(date)</p>
<p>Hostname: $(hostname) | Kernel: $(uname -r)</p>
</div>
HTMLEOF

    if [[ -n "${existing_reports}" ]]; then
        echo "${existing_reports}" | while read -r rpt; do
            local rname
            rname=$(basename "${rpt}" .txt)
            echo "<div class='report-section'>" >> "${report_file}"
            echo "<h2>${rname}</h2>" >> "${report_file}"
            echo "<pre>" >> "${report_file}"
            cat "${rpt}" >> "${report_file}"
            echo "</pre></div>" >> "${report_file}"
        done
    else
        echo "<p>No individual reports found. Run modules first, then generate report.</p>" >> "${report_file}"
    fi

    echo "</body></html>" >> "${report_file}"
    log SUCCESS "Report generated: ${report_file}"
    echo ""
}
