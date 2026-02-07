using ClosedXML.Excel;
using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using System.Data;
using System.Linq;

namespace ManejoPresupuestos.Servicios
{
    public interface ITransformToReport
    {
        byte[] GenerarExcelProduccionWip(ReporteProduccionWipViewModel vm);
        byte[] GenerarExcelPedido360(ReportePedido360ViewModel vm);
        byte[] GenerarExcelPedidosOperativos(ReportePedidosOperativosViewModel vm);
        byte[] GenerarExcelPagosPendientes(ReporteCxcViewModel vm);
        byte[] GenerarExcelCotizacionesSeguimiento(ReporteCotizacionesSeguimientoViewModel vm);
        byte[] GenerarExcelProduccionUtilizacion(ReporteProduccionUtilizacionViewModel vm);
        byte[] GenerarExcelInventarioConsumoMejorado(ReporteInventarioConsumoMejoradoViewModel vm);
        byte[] GenerarExcelComprasHistorico(ReporteComprasHistoricoVm vm);
    }
    public class TransformToReport : ITransformToReport
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioReportes repositorioReportes;

        public TransformToReport(
            IServicioUsuarios servicioUsuarios,
            IRepositorioReportes repositorioReportes
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioReportes = repositorioReportes;
        }


        public byte[] GenerarExcelProduccionWip(ReporteProduccionWipViewModel vm)
        {
            using var wb = new XLWorkbook();

            // -------------------------
            // Sheet: Resumen (KPIs + filtros)
            // -------------------------
            var wsResumen = wb.AddWorksheet("Resumen");
            wsResumen.Style.Font.FontName = "Calibri";
            wsResumen.Style.Font.FontSize = 11;

            wsResumen.Cell("A1").Value = "Producción (WIP + Carga)";
            wsResumen.Cell("A1").Style.Font.Bold = true;
            wsResumen.Cell("A1").Style.Font.FontSize = 16;

            wsResumen.Cell("A2").Value = "Tablero operativo: WIP por etapa, carga por impresora y antigüedad en cola";
            wsResumen.Cell("A2").Style.Font.FontSize = 10;
            wsResumen.Cell("A2").Style.Font.FontColor = XLColor.Gray;

            wsResumen.Cell("A3").Value = $"Generado: {DateTime.Now:yyyy-MM-dd HH:mm}";
            wsResumen.Cell("A3").Style.Font.FontSize = 9;
            wsResumen.Cell("A3").Style.Font.FontColor = XLColor.Gray;

            // Filtros
            wsResumen.Cell("A5").Value = "Filtros";
            wsResumen.Cell("A5").Style.Font.Bold = true;

            var filtros = new (string Label, string Value)[]
            {
                ("Desde", vm.Desde?.ToString("yyyy-MM-dd") ?? "-"),
                ("Hasta", vm.Hasta?.ToString("yyyy-MM-dd") ?? "-"),
                ("ClienteId", vm.ClienteId?.ToString() ?? "-"),
                ("PedidoId", vm.PedidoId?.ToString() ?? "-"),
                ("EstatusId", vm.EstatusId?.ToString() ?? "-"),
                ("ImpresoraId", vm.ImpresoraId?.ToString() ?? "-"),
                ("SoloWip", vm.SoloWip ? "Sí" : "No"),
                ("SoloAtrasados", vm.SoloAtrasados ? "Sí" : "No"),
                ("SinImpresora", vm.SinImpresora ? "Sí" : "No"),
                ("MinDiasCola", vm.MinDiasCola?.ToString() ?? "-"),
                ("Buscar (q)", string.IsNullOrWhiteSpace(vm.Q) ? "-" : vm.Q.Trim()),
            };

            int fr = 6;
            foreach (var f in filtros)
            {
                wsResumen.Cell(fr, 1).Value = f.Label;
                wsResumen.Cell(fr, 1).Style.Font.Bold = true;
                wsResumen.Cell(fr, 2).Value = f.Value;
                fr++;
            }

            // KPIs
            wsResumen.Cell("A18").Value = "KPIs";
            wsResumen.Cell("A18").Style.Font.Bold = true;

            wsResumen.Cell("A19").Value = "Items";
            wsResumen.Cell("B19").Value = vm.Totales.Items;

            wsResumen.Cell("A20").Value = "Cantidad total";
            wsResumen.Cell("B20").Value = vm.Totales.CantidadTotal;

            wsResumen.Cell("A21").Value = "WIP";
            wsResumen.Cell("B21").Value = vm.Totales.WipItems;

            wsResumen.Cell("A22").Value = "Finalizados";
            wsResumen.Cell("B22").Value = vm.Totales.FinalizadosItems;

            wsResumen.Cell("A23").Value = "Atrasados";
            wsResumen.Cell("B23").Value = vm.Totales.Atrasados;

            wsResumen.Cell("A24").Value = "Sin impresora";
            wsResumen.Cell("B24").Value = vm.Totales.SinImpresora;

            wsResumen.Cell("A25").Value = "Avg días en estatus";
            wsResumen.Cell("B25").Value = vm.Totales.AvgDiasEnEstatus;
            wsResumen.Cell("B25").Style.NumberFormat.Format = "0.0";

            wsResumen.Cell("A26").Value = "Max días en estatus";
            wsResumen.Cell("B26").Value = vm.Totales.MaxDiasEnEstatus;

            // Look pro
            var kpiRange = wsResumen.Range("A19:B26");
            kpiRange.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
            kpiRange.Style.Border.InsideBorder = XLBorderStyleValues.Thin;
            kpiRange.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            wsResumen.Column(1).Width = 22;
            wsResumen.Column(2).Width = 35;

            // -------------------------
            // Sheet: WIP por estatus
            // -------------------------
            var wsEstatus = wb.AddWorksheet("WIP por estatus");
            var dataEstatus = vm.WipPorEstatus
                .OrderBy(x => x.ProduccionEstatusOrden)
                .Select(x => new
                {
                    Estatus = x.ProduccionEstatusNombre,
                    Items = x.Items,
                    Cantidad = x.Cantidad,
                    Atrasados = x.Atrasados,
                    AvgDias = x.AvgDiasEnEstatus,
                    MaxDias = x.MaxDiasEnEstatus,
                    PesoEstimadoGr = x.PesoEstimadoTotalGr,
                    PesoRealGr = x.PesoRealTotalGr
                })
                .ToList();

            InsertarTabla(wsEstatus, dataEstatus, "tblEstatus");
            wsEstatus.Column(5).Style.NumberFormat.Format = "0.0"; // AvgDias
            wsEstatus.Column(7).Style.NumberFormat.Format = "#,##0.0"; // pesos
            wsEstatus.Column(8).Style.NumberFormat.Format = "#,##0.0";
            wsEstatus.SheetView.FreezeRows(1);

            // -------------------------
            // Sheet: Carga por impresora
            // -------------------------
            var wsImp = wb.AddWorksheet("Carga por impresora");
            var dataImp = vm.PorImpresora
                .OrderByDescending(x => x.WipItems)
                .ThenByDescending(x => x.Items)
                .Select(x => new
                {
                    Impresora = x.ImpresoraId.HasValue ? x.ImpresoraNombre : "(Sin impresora)",
                    Modelo = x.ImpresoraModelo ?? "",
                    Items = x.Items,
                    Cantidad = x.Cantidad,
                    WIP = x.WipItems,
                    Atrasados = x.Atrasados,
                    AvgDias = x.AvgDiasEnEstatus,
                    MaxDias = x.MaxDiasEnEstatus
                })
                .ToList();

            InsertarTabla(wsImp, dataImp, "tblImpresoras");
            wsImp.Column(7).Style.NumberFormat.Format = "0.0";
            wsImp.SheetView.FreezeRows(1);

            // -------------------------
            // Sheet: Antiguedad (cola)
            // -------------------------
            var wsCola = wb.AddWorksheet("Antigüedad (cola)");
            var dataCola = vm.PorAntiguedad
                .OrderBy(x => x.ColaBucketId)
                .Select(x => new
                {
                    Bucket = x.ColaBucketNombre,
                    Items = x.Items,
                    Cantidad = x.Cantidad,
                    Atrasados = x.Atrasados,
                    AvgDias = x.AvgDiasEnEstatus,
                    MaxDias = x.MaxDiasEnEstatus
                })
                .ToList();

            InsertarTabla(wsCola, dataCola, "tblCola");
            wsCola.Column(5).Style.NumberFormat.Format = "0.0";
            wsCola.SheetView.FreezeRows(1);

            // -------------------------
            // Sheet: Detalle
            // -------------------------
            var wsDet = wb.AddWorksheet("Detalle");
            var dataDet = vm.Detalle.Select(x => new
            {
                ProdItemId = x.ProduccionItemId,
                PedidoId = x.PedidoId,
                PedidoItemId = x.PedidoItemId,
                Cliente = x.ClienteNombre,
                Producto = x.ProductoNombre,
                Cantidad = x.Cantidad,
                Estatus = x.ProduccionEstatusNombre,
                Impresora = x.ImpresoraId.HasValue ? x.ImpresoraNombre : "(Sin impresora)",
                DiasEnEstatus = x.DiasEnEstatus,
                FechaEnEstatus = x.FechaEnEstatus,
                EntregaEstimada = x.FechaEntregaEstimada,
                Atrasado = x.Atrasado ? "Sí" : "No",
                WIP = x.EsWip ? "Sí" : "No",
                Bucket = x.ColaBucketNombre,
                PesoEstimadoGr = x.PesoEstimadoGr,
                PesoRealGr = x.PesoRealGr,
                InventarioAplicado = x.InventarioAplicado ? "Sí" : "No",
                Notas = x.Notas,
                NotasOperativas = x.NotasOperativas
            }).ToList();

            var tblDet = InsertarTabla(wsDet, dataDet, "tblDetalle");
            wsDet.SheetView.FreezeRows(1);

            // Formatos (fechas y decimales)
            // Ubica columnas por índice (según el select)
            wsDet.Column(10).Style.DateFormat.Format = "yyyy-mm-dd";  // FechaEnEstatus
            wsDet.Column(11).Style.DateFormat.Format = "yyyy-mm-dd";  // EntregaEstimada
            wsDet.Column(15).Style.NumberFormat.Format = "#,##0.0";   // PesoEstimadoGr
            wsDet.Column(16).Style.NumberFormat.Format = "#,##0.0";   // PesoRealGr

            // Notas con wrap y ancho razonable
            wsDet.Column(18).Width = 35;
            wsDet.Column(19).Width = 35;
            wsDet.Column(18).Style.Alignment.WrapText = true;
            wsDet.Column(19).Style.Alignment.WrapText = true;

            // Ajustes generales
            wsResumen.Columns().AdjustToContents();
            wsEstatus.Columns().AdjustToContents();
            wsImp.Columns().AdjustToContents();
            wsCola.Columns().AdjustToContents();
            wsDet.Columns().AdjustToContents(1, 120);

            using var ms = new MemoryStream();
            wb.SaveAs(ms);
            return ms.ToArray();
        }

        private static IXLTable InsertarTabla<T>(IXLWorksheet ws, List<T> data, string tableName)
        {
            if (data.Count == 0)
            {
                ws.Cell("A1").Value = "Sin datos";
                ws.Cell("A1").Style.Font.FontColor = XLColor.Gray;
                return null!;
            }

            var table = ws.Cell(1, 1).InsertTable(data, tableName, true);
            table.Theme = XLTableTheme.TableStyleMedium9;

            // Header look
            var header = table.Range(1, 1, 1, table.ColumnCount());
            header.Style.Font.Bold = true;
            header.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

            // Bordes suaves
            table.RangeUsed().Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
            table.RangeUsed().Style.Border.InsideBorder = XLBorderStyleValues.Thin;

            return table;
        }

        public byte[] GenerarExcelPedido360(ReportePedido360ViewModel vm)
        {
            using var wb = new XLWorkbook();
            var ws = wb.AddWorksheet("Pedido 360");

            ws.Style.Font.FontName = "Calibri";
            ws.Style.Font.FontSize = 11;

            const int MAX_COL = 18; // A..R
            int r = 1;

            // Paleta (uniforme, no chillona)
            var cTitle    = XLColor.FromHtml("#0F172A"); // slate-900
            var cTeal     = XLColor.FromHtml("#0F766E"); // teal-700
            var cPurple   = XLColor.FromHtml("#5B21B6"); // violet-800
            var cOrange   = XLColor.FromHtml("#9A3412"); // orange-800
            var cGreen    = XLColor.FromHtml("#166534"); // green-800
            var cBlueGray = XLColor.FromHtml("#1E293B"); // slate-800
            var cSlate    = XLColor.FromHtml("#334155"); // slate-700
            var cSoftGray = XLColor.FromHtml("#F1F5F9"); // slate-100
            var cZebra    = XLColor.FromHtml("#F8FAFC"); // zebra

            // --- Título ---
            var title = ws.Range(r, 1, r, MAX_COL);
            title.Merge();
            title.FirstCell().Value = $"Pedido 360 — Pedido #{vm.PedidoId}";
            title.Style.Font.Bold = true;
            title.Style.Font.FontSize = 16;
            title.Style.Font.FontColor = XLColor.White;
            title.Style.Fill.BackgroundColor = cTitle;
            title.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            title.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Row(r).Height = 26;
            r++;

            var gen = ws.Range(r, 1, r, MAX_COL);
            gen.Merge();
            gen.FirstCell().Value = $"Generado: {DateTime.Now:yyyy-MM-dd HH:mm}";
            gen.Style.Font.FontSize = 9;
            gen.Style.Font.FontColor = XLColor.Gray;
            gen.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            r += 2;

            // Si no hay header (no encontrado)
            if (vm.Header is null)
            {
                var msg = ws.Range(r, 1, r, MAX_COL);
                msg.Merge();
                msg.FirstCell().Value = string.IsNullOrWhiteSpace(vm.Mensaje)
                    ? "No se encontró el pedido o no tienes acceso."
                    : vm.Mensaje;

                msg.Style.Fill.BackgroundColor = XLColor.FromHtml("#FEF3C7");
                msg.Style.Font.Bold = true;
                msg.Style.Font.FontColor = XLColor.FromHtml("#92400E");
                msg.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                msg.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
                ws.Row(r).Height = 22;

                ws.Columns(1, MAX_COL).AdjustToContents(1, 80);
                using var ms0 = new MemoryStream();
                wb.SaveAs(ms0);
                return ms0.ToArray();
            }

            var h = vm.Header;

            // Totales (igual que tu vista)
            var cotItems = vm.Cotizacion.Where(x => x.RowType == "ITEM").ToList();
            var totalCot = cotItems.Sum(x => x.Subtotal ?? 0m);
            var totalPagado = vm.Pagos.Where(p => p.EstaActivo).Sum(p => p.Monto);
            var pendiente = totalCot - totalPagado;

            // --- Seccion: Cliente y pedido ---
            r = EscribirTituloSeccion(ws, r, "Cliente y pedido", cTeal, MAX_COL);

            // Bloque izquierda (cliente)
            r = EscribirKV(ws, r, 1, "Cliente", h.ClienteNombre ?? "-", 3, cSoftGray);
            r = EscribirKV(ws, r, 1, "Teléfono", h.Telefono ?? "-", 3, cSoftGray);
            r = EscribirKV(ws, r, 1, "WhatsApp", h.WhatsApp ?? "-", 3, cSoftGray);
            r = EscribirKV(ws, r, 1, "Instagram", h.Instagram ?? "-", 3, cSoftGray);
            r = EscribirKV(ws, r, 1, "Email", h.Email ?? "-", 3, cSoftGray);
            r = EscribirKV(ws, r, 1, "Dirección", h.Direccion ?? "-", 3, cSoftGray);

            // Bloque derecha (pedido) -> empieza en 9 para NO pisarse con el bloque cliente
            int r2 = r - 6;
            EscribirKVInline(ws, r2 + 0, 9, "PedidoId", h.PedidoId.ToString(), 3, 3, cSoftGray);
            EscribirKVInline(ws, r2 + 1, 9, "Estatus", h.PedidoEstatusNombre ?? "-", 3, 3, cSoftGray);
            EscribirKVInline(ws, r2 + 2, 9, "Creación", h.FechaCreacion.ToString("yyyy-MM-dd HH:mm"), 3, 3, cSoftGray);
            EscribirKVInline(ws, r2 + 3, 9, "Entrega estimada", h.FechaEntregaEstimada?.ToString("yyyy-MM-dd") ?? "-", 3, 3, cSoftGray);
            EscribirKVInline(ws, r2 + 4, 9, "CotizaciónId", h.CotizacionIdVinculada?.ToString() ?? "-", 3, 3, cSoftGray);

            // Notas (merge ancho)
            ws.Cell(r, 1).Value = "Notas";
            ws.Cell(r, 1).Style.Font.Bold = true;
            var notasRange = ws.Range(r, 2, r, MAX_COL);
            notasRange.Merge();
            notasRange.FirstCell().Value = string.IsNullOrWhiteSpace(h.Notas) ? "-" : h.Notas;
            notasRange.Style.Fill.BackgroundColor = cSoftGray;
            notasRange.Style.Alignment.WrapText = true;
            notasRange.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
            ws.Row(r).Height = 28;
            r += 2;

            // --- Seccion: Totales ---
            r = EscribirTituloSeccion(ws, r, "Totales", cGreen, MAX_COL);

            EscribirMoney(ws, r, 1, "Total estimado", h.TotalEstimado ?? 0m, 3); r++;
            EscribirMoney(ws, r, 1, "Total cotización", totalCot, 3); r++;
            EscribirMoney(ws, r, 1, "Pagado", totalPagado, 3); r++;
            EscribirMoney(ws, r, 1, "Pendiente", pendiente, 3); r += 2;

            // ==========================
            // TABLA: Items del pedido
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Items del pedido", cBlueGray, MAX_COL);

            var dtItems = new DataTable("ItemsPedido");
            dtItems.Columns.AddRange(new[]
            {
                new DataColumn("PedidoItemId"),
                new DataColumn("Producto"),
                new DataColumn("Categoría"),
                new DataColumn("Cantidad", typeof(int)),
                new DataColumn("Precio Est.", typeof(decimal)),
                new DataColumn("ProdItems", typeof(int)),
                new DataColumn("Cant. Prod", typeof(int)),
                new DataColumn("Peso Est. (gr)", typeof(decimal)),
                new DataColumn("Peso Real (gr)", typeof(decimal)),
                new DataColumn("Notas"),
                new DataColumn("Activo"),
            });

            foreach (var i in vm.Items.OrderBy(x => x.PedidoItemId))
            {
                dtItems.Rows.Add(
                    i.PedidoItemId,
                    i.ProductoNombre ?? i.ProductoId.ToString(),
                    i.ProductoCategoriaNombre ?? "-",
                    i.Cantidad,
                    i.PrecioUnitarioEstimado ?? 0m,
                    i.ProduccionItems,
                    i.CantidadEnProduccion,
                    i.PesoEstimadoGrTotal,
                    i.PesoRealGrTotal,
                    i.Notas ?? "-",
                    i.EstaActivo ? "Sí" : "No"
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtItems, "tblPedidoItems", cBlueGray, MAX_COL, cZebra, out var tblItems) + 2;
            AplicarFormatosTabla(tblItems, new()
            {
                ["Precio Est."] = "#,##0.00",
                ["Peso Est. (gr)"] = "#,##0.00",
                ["Peso Real (gr)"] = "#,##0.00",
            });
            PintarInactivos(tblItems, "Activo", "No", XLColor.FromHtml("#E5E7EB"));

            // ==========================
            // COTIZACION: Header + Items
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Cotización vinculada", cPurple, MAX_COL);

            var cotHeader = vm.Cotizacion.FirstOrDefault(x => x.RowType == "HEADER");
            if (cotHeader is null && !cotItems.Any())
            {
                r = EscribirSinDatos(ws, r, "Sin cotización vinculada.", MAX_COL) + 2;
            }
            else
            {
                if (cotHeader is not null)
                {
                    // 4 bloques perfectos en 18 columnas -> NO se pisan
                    EscribirKVInline(ws, r, 1,  "CotizaciónId", cotHeader.CotizacionId.ToString(), 2, 2, cSoftGray);
                    EscribirKVInline(ws, r, 5,  "Estatus",      cotHeader.CotizacionEstatusNombre ?? "-", 2, 2, cSoftGray);
                    EscribirKVInline(ws, r, 9,  "Creación",     cotHeader.FechaCreacion.ToString("yyyy-MM-dd"), 2, 2, cSoftGray);
                    EscribirKVInline(ws, r, 13, "Vigencia",     cotHeader.FechaVigencia?.ToString("yyyy-MM-dd") ?? "-", 2, 2, cSoftGray);
                    r++;

                    ws.Cell(r, 1).Value = "Notas cotización";
                    ws.Cell(r, 1).Style.Font.Bold = true;
                    var rn = ws.Range(r, 2, r, MAX_COL);
                    rn.Merge();
                    rn.FirstCell().Value = string.IsNullOrWhiteSpace(cotHeader.Notas) ? "-" : cotHeader.Notas;
                    rn.Style.Fill.BackgroundColor = cSoftGray;
                    rn.Style.Alignment.WrapText = true;
                    rn.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                    ws.Row(r).Height = 26;
                    r += 2;
                }

                var dtCot = new DataTable("CotizacionItems");
                dtCot.Columns.AddRange(new[]
                {
                    new DataColumn("ItemId"),
                    new DataColumn("Tipo"),
                    new DataColumn("Concepto"),
                    new DataColumn("Producto"),
                    new DataColumn("Cantidad", typeof(decimal)),
                    new DataColumn("P.U.", typeof(decimal)),
                    new DataColumn("Subtotal", typeof(decimal)),
                    new DataColumn("Notas"),
                });

                foreach (var ci in cotItems.OrderBy(x => x.CotizacionItemId))
                {
                    dtCot.Rows.Add(
                        ci.CotizacionItemId?.ToString() ?? "-",
                        ci.ConceptoTipoNombre ?? ci.ConceptoTipoId?.ToString() ?? "-",
                        ci.Concepto ?? "-",
                        ci.ProductoNombre ?? "-",
                        ci.Cantidad ?? 0m,
                        ci.PrecioUnitario ?? 0m,
                        ci.Subtotal ?? 0m,
                        ci.ItemNotas ?? "-"
                    );
                }

                r = InsertarTablaAt(ws, r, 1, dtCot, "tblCotItems", cPurple, MAX_COL, cZebra, out var tblCot) + 1;
                AplicarFormatosTabla(tblCot, new()
                {
                    ["Cantidad"] = "#,##0.00",
                    ["P.U."] = "#,##0.00",
                    ["Subtotal"] = "#,##0.00",
                });

                // Total debajo
                ws.Cell(r, 1).Value = "Total cotización";
                ws.Range(r, 1, r, 6).Merge().Style.Font.Bold = true;
                ws.Cell(r, 7).Value = totalCot;
                ws.Cell(r, 7).Style.NumberFormat.Format = "#,##0.00";
                ws.Cell(r, 7).Style.Font.Bold = true;
                r += 2;
            }

            // ==========================
            // PAGOS
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Pagos", cOrange, MAX_COL);

            var dtPagos = new DataTable("Pagos");
            dtPagos.Columns.AddRange(new[]
            {
                new DataColumn("PagoId"),
                new DataColumn("Tipo"),
                new DataColumn("Fecha", typeof(DateTime)),
                new DataColumn("Método"),
                new DataColumn("Referencia"),
                new DataColumn("Notas"),
                new DataColumn("Monto", typeof(decimal)),
                new DataColumn("Activo"),
            });

            foreach (var p in vm.Pagos.OrderByDescending(x => x.FechaPago))
            {
                dtPagos.Rows.Add(
                    p.PagoId,
                    p.PagoTipoNombre ?? p.PagoTipoId.ToString(),
                    p.FechaPago.Date,
                    p.Metodo ?? "-",
                    p.Referencia ?? "-",
                    p.Notas ?? "-",
                    p.Monto,
                    p.EstaActivo ? "Sí" : "No"
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtPagos, "tblPagos", cOrange, MAX_COL, cZebra, out var tblPagos) + 2;
            AplicarFormatosTabla(tblPagos, new()
            {
                ["Fecha"] = "yyyy-mm-dd",
                ["Monto"] = "#,##0.00",
            });
            PintarInactivos(tblPagos, "Activo", "No", XLColor.FromHtml("#E5E7EB"));

            // ==========================
            // PRODUCCION
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Producción", cTeal, MAX_COL);

            var dtProd = new DataTable("Produccion");
            dtProd.Columns.AddRange(new[]
            {
                new DataColumn("ProdItemId"),
                new DataColumn("PedidoItemId"),
                new DataColumn("Producto"),
                new DataColumn("Cantidad", typeof(int)),
                new DataColumn("Estatus"),
                new DataColumn("Impresora"),
                new DataColumn("Receta"),
                new DataColumn("Peso Est. (gr)", typeof(decimal)),
                new DataColumn("Peso Real (gr)", typeof(decimal)),
                new DataColumn("Inicio"),
                new DataColumn("Fin"),
                new DataColumn("Inventario aplicado"),
            });

            foreach (var pr in vm.Produccion.OrderBy(x => x.ProduccionEstatusOrden).ThenBy(x => x.ProduccionItemId))
            {
                dtProd.Rows.Add(
                    pr.ProduccionItemId,
                    pr.PedidoItemId,
                    pr.ProductoNombre ?? pr.ProductoId.ToString(),
                    pr.Cantidad,
                    pr.ProduccionEstatusNombre ?? "-",
                    pr.ImpresoraNombre ?? "-",
                    pr.RecetaNombre ?? "-",
                    pr.PesoEstimadoGr ?? 0m,
                    pr.PesoRealGr ?? 0m,
                    pr.FechaInicio?.ToString("yyyy-MM-dd HH:mm") ?? "-",
                    pr.FechaFin?.ToString("yyyy-MM-dd HH:mm") ?? "-",
                    pr.InventarioAplicado ? "Sí" : "No"
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtProd, "tblProduccion360", cTeal, MAX_COL, cZebra, out var tblProd) + 2;
            AplicarFormatosTabla(tblProd, new()
            {
                ["Peso Est. (gr)"] = "#,##0.00",
                ["Peso Real (gr)"] = "#,##0.00",
            });

            // ==========================
            // CONSUMO
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Consumo de inventario (por receta/insumo)", cGreen, MAX_COL);

            var dtCons = new DataTable("Consumo");
            dtCons.Columns.AddRange(new[]
            {
                new DataColumn("Fecha"),
                new DataColumn("ProdItem"),
                new DataColumn("PedidoItem"),
                new DataColumn("Receta"),
                new DataColumn("Inventario"),
                new DataColumn("Unidad"),
                new DataColumn("Planeado", typeof(decimal)),
                new DataColumn("Cantidad", typeof(decimal)),
                new DataColumn("Antes", typeof(decimal)),
                new DataColumn("Después", typeof(decimal)),
                new DataColumn("Notas"),
            });

            foreach (var c in vm.Consumo.OrderByDescending(x => x.Fecha))
            {
                dtCons.Rows.Add(
                    c.Fecha.ToString("yyyy-MM-dd HH:mm"),
                    c.ProduccionItemId,
                    c.PedidoItemId?.ToString() ?? "-",
                    c.RecetaNombre ?? c.RecetaId?.ToString() ?? "-",
                    c.InsumoNombre ?? c.InventarioId.ToString(),
                    c.UnidadNombre ?? "-",
                    c.CantidadPlaneadaTotal ?? 0m,
                    c.CantidadConsumida,
                    c.DisponibleAntes ?? 0m,
                    c.DisponibleDespues ?? 0m,
                    c.Notas ?? "-"
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtCons, "tblConsumo360", cGreen, MAX_COL, cZebra, out var tblCons) + 2;
            AplicarFormatosTabla(tblCons, new()
            {
                ["Planeado"] = "#,##0.00",
                ["Cantidad"] = "#,##0.00",
                ["Antes"] = "#,##0.00",
                ["Después"] = "#,##0.00",
            });

            // ==========================
            // TIMELINE
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Timeline", cSlate, MAX_COL);

            var dtHist = new DataTable("Timeline");
            dtHist.Columns.AddRange(new[]
            {
                new DataColumn("Fecha"),
                new DataColumn("Tipo"),
                new DataColumn("PedidoItem"),
                new DataColumn("ProdItem"),
                new DataColumn("Desde"),
                new DataColumn("Hacia"),
                new DataColumn("Notas"),
            });

            foreach (var hi in vm.Historia.OrderByDescending(x => x.Fecha))
            {
                dtHist.Rows.Add(
                    hi.Fecha.ToString("yyyy-MM-dd HH:mm"),
                    hi.Tipo,
                    hi.PedidoItemId?.ToString() ?? "-",
                    hi.ProduccionItemId?.ToString() ?? "-",
                    hi.DesdeEstatusNombre ?? hi.DesdeEstatusId.ToString(),
                    hi.HaciaEstatusNombre ?? hi.HaciaEstatusId.ToString(),
                    hi.Notas ?? "-"
                );
            }

            _ = InsertarTablaAt(ws, r, 1, dtHist, "tblTimeline360", cSlate, MAX_COL, cZebra, out var tblHist);

            // wrap para notas en timeline
            if (tblHist != null && TieneCampo(tblHist, "Notas"))
                tblHist.Field("Notas").Column.Style.Alignment.WrapText = true;

            // Ajustes finales
            ws.SheetView.FreezeRows(3);
            ws.PageSetup.PageOrientation = XLPageOrientation.Landscape;
            ws.PageSetup.FitToPages(1, 0);
            ws.PageSetup.CenterHorizontally = true;

            ws.Columns(1, MAX_COL).AdjustToContents(1, 80);
            // notas suelen ocupar mucho
            ws.Column(10).Width = Math.Max(ws.Column(10).Width, 28);
            ws.Column(11).Width = Math.Max(ws.Column(11).Width, 28);

            using var ms = new MemoryStream();
            wb.SaveAs(ms);
            return ms.ToArray();
        }

        // ===================== Helpers (solo para Pedido360) =====================

        private static int EscribirTituloSeccion(IXLWorksheet ws, int row, string titulo, XLColor color, int maxCol)
        {
            var rg = ws.Range(row, 1, row, maxCol);
            rg.Merge();
            rg.FirstCell().Value = titulo;
            rg.Style.Fill.BackgroundColor = color;
            rg.Style.Font.Bold = true;
            rg.Style.Font.FontColor = XLColor.White;
            rg.Style.Font.FontSize = 12;
            rg.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Row(row).Height = 20;
            return row + 1;
        }

        private static int EscribirKV(IXLWorksheet ws, int row, int col, string label, string value, int labelSpan, XLColor bg)
        {
            ws.Cell(row, col).Value = label;
            var lbl = ws.Range(row, col, row, col + (labelSpan - 1));
            lbl.Merge();
            lbl.Style.Font.Bold = true;

            var val = ws.Range(row, col + labelSpan, row, col + labelSpan + 4);
            val.Merge();
            val.FirstCell().Value = value;
            val.Style.Fill.BackgroundColor = bg;
            val.Style.Alignment.WrapText = true;

            // borde sutil tipo “card”
            lbl.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
            val.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;

            return row + 1;
        }

        private static void EscribirKVInline(
            IXLWorksheet ws,
            int row,
            int col,
            string label,
            string value,
            int labelSpan,
            int valueSpan,
            XLColor bg
        )
        {
            ws.Cell(row, col).Value = label;

            var lbl = ws.Range(row, col, row, col + (labelSpan - 1));
            lbl.Merge();
            lbl.Style.Font.Bold = true;

            var val = ws.Range(row, col + labelSpan, row, col + labelSpan + (valueSpan - 1));
            val.Merge();
            val.FirstCell().Value = value;
            val.Style.Fill.BackgroundColor = bg;

            lbl.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
            val.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
        }

        private static void EscribirMoney(IXLWorksheet ws, int row, int col, string label, decimal value, int labelSpan)
        {
            ws.Cell(row, col).Value = label;
            ws.Range(row, col, row, col + (labelSpan - 1)).Merge().Style.Font.Bold = true;

            var cell = ws.Cell(row, col + labelSpan);
            cell.Value = value;
            cell.Style.NumberFormat.Format = "#,##0.00";
            cell.Style.Font.Bold = true;
            cell.Style.Fill.BackgroundColor = XLColor.FromHtml("#ECFDF5"); // verde suave
        }

        private static int EscribirSinDatos(IXLWorksheet ws, int row, string texto, int maxCol)
        {
            var rg = ws.Range(row, 1, row, maxCol);
            rg.Merge();
            rg.FirstCell().Value = texto;
            rg.Style.Font.FontColor = XLColor.Gray;
            rg.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            rg.Style.Fill.BackgroundColor = XLColor.FromHtml("#F9FAFB");
            ws.Row(row).Height = 18;
            return row + 1;
        }

        private static int InsertarTablaAt(
            IXLWorksheet ws,
            int startRow,
            int startCol,
            DataTable dt,
            string tableName,
            XLColor headerColor,
            int maxCol,
            XLColor zebraColor,
            out IXLTable? table
        )
        {
            table = null;

            if (dt.Rows.Count == 0)
                return EscribirSinDatos(ws, startRow, "Sin datos.", maxCol);

            table = ws.Cell(startRow, startCol).InsertTable(dt, tableName, true);

            // Header pro (color por seccion)
            var header = table.Range(1, 1, 1, table.ColumnCount());
            header.Style.Fill.BackgroundColor = headerColor;
            header.Style.Font.FontColor = XLColor.White;
            header.Style.Font.Bold = true;
            header.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            header.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;

            // Cuerpo: bordes + altura cómoda
            table.RangeUsed().Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
            table.RangeUsed().Style.Border.InsideBorder = XLBorderStyleValues.Thin;
            table.RangeUsed().Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;

            // Zebra suave manual
            var dataRange = table.DataRange;
            for (int i = 1; i <= dataRange.RowCount(); i++)
            {
                if (i % 2 == 0)
                    dataRange.Row(i).Style.Fill.BackgroundColor = zebraColor;
            }

            return table.RangeUsed().LastRow().RowNumber();
        }

        private static bool TieneCampo(IXLTable t, string fieldName)
            => t.Fields.Any(f => string.Equals(f.Name, fieldName, StringComparison.OrdinalIgnoreCase));

        private static void AplicarFormatosTabla(IXLTable? t, Dictionary<string, string> formatos)
        {
            if (t is null) return;
            if (t.DataRange is null) return;

            foreach (var kv in formatos)
            {
                var name = kv.Key;
                var fmt = kv.Value;

                var fieldPos = ObtenerPosCampo1Based(t, name);
                if (fieldPos == 0) continue;

                var colRange = ObtenerRangoDatosColumna(t, fieldPos);
                colRange.Style.NumberFormat.Format = fmt;
                colRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Right;
            }
        }

        private static void PintarInactivos(IXLTable? t, string colName, string equals, XLColor color)
        {
            if (t is null) return;
            if (t.DataRange is null) return;

            var fieldPos = ObtenerPosCampo1Based(t, colName);
            if (fieldPos == 0) return;

            var colRange = ObtenerRangoDatosColumna(t, fieldPos);

            colRange.AddConditionalFormat()
                .WhenEquals(equals)
                .Fill.SetBackgroundColor(color);
        }

        private static int ObtenerPosCampo1Based(IXLTable t, string fieldName)
        {
            var i = 1;
            foreach (var f in t.Fields)
            {
                if (string.Equals(f.Name, fieldName, StringComparison.OrdinalIgnoreCase))
                    return i;
                i++;
            }
            return 0;
        }

        private static IXLRange ObtenerRangoDatosColumna(IXLTable t, int fieldPos1Based)
        {
            var dr = t.DataRange!;

            var firstRow = dr.RangeAddress.FirstAddress.RowNumber;
            var lastRow = dr.RangeAddress.LastAddress.RowNumber;

            var firstCol = dr.RangeAddress.FirstAddress.ColumnNumber;
            var colNumber = firstCol + fieldPos1Based - 1;

            return dr.Worksheet.Range(firstRow, colNumber, lastRow, colNumber);
        }

        public byte[] GenerarExcelPedidosOperativos(ReportePedidosOperativosViewModel vm)
        {
            using var wb = new XLWorkbook();
            var ws = wb.AddWorksheet("Pedidos operativos");

            ws.Style.Font.FontName = "Calibri";
            ws.Style.Font.FontSize = 11;
            // ws.SheetView.ShowGridLines = false;

            const int MAX_COL = 18; // A..R
            int r = 1;

            // Paleta (igual estilo que Pedido360, sobria)
            var cTitle    = XLColor.FromHtml("#0F172A"); // slate-900
            var cTeal     = XLColor.FromHtml("#0F766E"); // teal-700
            var cBlueGray = XLColor.FromHtml("#1E293B"); // slate-800
            var cSlate    = XLColor.FromHtml("#334155"); // slate-700
            var cSoftGray = XLColor.FromHtml("#F1F5F9"); // slate-100
            var cZebra    = XLColor.FromHtml("#F8FAFC"); // zebra
            var cWarnRow  = XLColor.FromHtml("#FEF3C7"); // warning suave

            // ---------- helpers locales ----------
            string NombreLookup(List<ReporteOpcionRow> list, int? id)
            {
                if (!id.HasValue) return "Todos";
                return list.FirstOrDefault(x => x.Id == id.Value)?.Nombre ?? id.Value.ToString();
            }

            // --- Título ---
            var title = ws.Range(r, 1, r, MAX_COL);
            title.Merge();
            title.FirstCell().Value = "Pedidos operativos";
            title.Style.Font.Bold = true;
            title.Style.Font.FontSize = 16;
            title.Style.Font.FontColor = XLColor.White;
            title.Style.Fill.BackgroundColor = cTitle;
            title.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            title.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Row(r).Height = 26;
            r++;

            var gen = ws.Range(r, 1, r, MAX_COL);
            gen.Merge();
            gen.FirstCell().Value = $"Generado: {DateTime.Now:yyyy-MM-dd HH:mm}";
            gen.Style.Font.FontSize = 9;
            gen.Style.Font.FontColor = XLColor.Gray;
            gen.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            r += 2;

            // ==========================
            // FILTROS
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Filtros", cSlate, MAX_COL);

            var desde = vm.Desde.ToString("yyyy-MM-dd");
            var hasta = vm.Hasta.ToString("yyyy-MM-dd");
            var estPedido = NombreLookup(vm.EstatusPedido, vm.PedidoEstatusId);
            var cliente = NombreLookup(vm.Clientes, vm.ClienteId);
            var estProd = NombreLookup(vm.EstatusProduccion, vm.ProduccionEstatusId);
            var canal = string.IsNullOrWhiteSpace(vm.Canal) ? "-" : vm.Canal.Trim();
            var soloAtrasados = vm.SoloAtrasados ? "Sí" : "No";

            // fila 1 filtros
            EscribirKVInline(ws, r, 1,  "Desde",         desde,     2, 2, cSoftGray);
            EscribirKVInline(ws, r, 5,  "Hasta",         hasta,     2, 2, cSoftGray);
            EscribirKVInline(ws, r, 9,  "Estatus pedido",estPedido, 2, 4, cSoftGray);
            EscribirKVInline(ws, r, 15, "Cliente",       cliente,   2, 2, cSoftGray);
            r++;

            // fila 2 filtros
            EscribirKVInline(ws, r, 1,  "Estatus prod.", estProd,       2, 4, cSoftGray);
            EscribirKVInline(ws, r, 7,  "Canal",         canal,         2, 6, cSoftGray);
            EscribirKVInline(ws, r, 15, "Solo atrasados",soloAtrasados, 2, 2, cSoftGray);
            r += 2;

            // ==========================
            // KPIs (cards)
            // ==========================
            r = EscribirTituloSeccion(ws, r, "KPIs", cTeal, MAX_COL);

            EscribirKpiCard(ws, r,  1,  4, "Pedidos",     vm.TotalPedidos.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r,  5,  8, "Atrasados",   vm.TotalAtrasados.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r,  9, 12, "Saldo total", vm.TotalSaldo.ToString("N2"), cSoftGray, isMoney: true);
            EscribirKpiCard(ws, r, 13, 18, "Rango",       $"{vm.Desde:yyyy-MM-dd} → {vm.Hasta:yyyy-MM-dd}", cSoftGray);

            // rojo si saldo negativo
            if (vm.TotalSaldo < 0)
            {
                // celda de valor del card 3 (Saldo total)
                ws.Cell(r + 1, 9).Style.Font.FontColor = XLColor.FromHtml("#B91C1C"); // red-700
            }

            r += 3; // card ocupa 2 filas + 1 separacion

            // ==========================
            // TABLA
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Tablero diario", cBlueGray, MAX_COL);

            var dt = new DataTable("PedidosOperativos");
            dt.Columns.Add("Prioridad", typeof(int));
            dt.Columns.Add("Pedido", typeof(int));
            dt.Columns.Add("Cliente");
            dt.Columns.Add("Total", typeof(decimal));
            dt.Columns.Add("Pagado %", typeof(decimal)); // ratio 0..1
            dt.Columns.Add("Saldo", typeof(decimal));
            dt.Columns.Add("Estatus pedido");
            dt.Columns.Add("Estatus producción");
            dt.Columns.Add("Fecha estimada", typeof(DateTime));
            dt.Columns.Add("Atraso");

            foreach (var x in vm.Rows
                .OrderBy(x => x.Prioridad)
                .ThenBy(x => x.FechaEntregaEstimada ?? DateTime.MaxValue)
                .ThenBy(x => x.PedidoId))
            {
                var pctRaw = x.PagadoPorcentaje;
                var pct = pctRaw > 1m ? pctRaw / 100m : pctRaw; // soporta 100 o 1.0

                dt.Rows.Add(
                    x.Prioridad,
                    x.PedidoId,
                    x.ClienteNombre ?? "-",
                    x.Total,
                    pct,
                    x.Saldo,
                    x.PedidoEstatusNombre ?? "-",
                    string.IsNullOrWhiteSpace(x.ProduccionEstatusNombre) ? "Sin producción" : x.ProduccionEstatusNombre!,
                    x.FechaEntregaEstimada.HasValue ? x.FechaEntregaEstimada.Value.Date : DBNull.Value,
                    x.EsAtrasado ? $"Sí ({x.DiasAtraso}d)" : "No"
                );
            }

            var lastRow = InsertarTablaAt(
                ws,
                r,
                1,
                dt,
                "tblPedidosOperativos",
                cBlueGray,
                MAX_COL,
                cZebra,
                out var tbl
            );

            // formatos
            if (tbl != null)
            {
                // money + percent
                AplicarFormatosTabla(tbl, new()
                {
                    ["Total"]    = "#,##0.00",
                    ["Saldo"]    = "#,##0.00;[Red]-#,##0.00",
                    ["Pagado %"] = "0.00%",
                });

                // fecha
                if (TieneCampo(tbl, "Fecha estimada"))
                {
                    var posFecha = ObtenerPosCampo1Based(tbl, "Fecha estimada");
                    var rngFecha = ObtenerRangoDatosColumna(tbl, posFecha);
                    rngFecha.Style.DateFormat.Format = "yyyy-mm-dd";
                    rngFecha.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                }

                // alinear numeros a la derecha (por si alguna col quedo sin formato)
                foreach (var name in new[] { "Prioridad", "Pedido", "Total", "Pagado %", "Saldo" })
                {
                    if (!TieneCampo(tbl, name)) continue;
                    var pos = ObtenerPosCampo1Based(tbl, name);
                    var rng = ObtenerRangoDatosColumna(tbl, pos);
                    rng.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Right;
                }

                // resaltar atrasados (fila completa)
                if (tbl.DataRange != null && TieneCampo(tbl, "Atraso"))
                {
                    var posAtraso = ObtenerPosCampo1Based(tbl, "Atraso");
                    var dr = tbl.DataRange;

                    for (int i = 1; i <= dr.RowCount(); i++)
                    {
                        var val = dr.Row(i).Cell(posAtraso).GetString();
                        if (val.StartsWith("Sí", StringComparison.OrdinalIgnoreCase))
                        {
                            dr.Row(i).Style.Fill.BackgroundColor = cWarnRow;
                        }
                    }
                }

                // freeze hasta el header de la tabla (para que se queden título/filtros/kpis)
                ws.SheetView.FreezeRows(tbl.RangeAddress.FirstAddress.RowNumber);

                // anchos minimos útiles
                // (col 3 cliente, 7-8 estatus, 10 atraso)
                ws.Column(3).Width = Math.Max(ws.Column(3).Width, 24);
                ws.Column(7).Width = Math.Max(ws.Column(7).Width, 18);
                ws.Column(8).Width = Math.Max(ws.Column(8).Width, 18);
                ws.Column(10).Width = Math.Max(ws.Column(10).Width, 12);
            }

            // ajustes finales
            ws.PageSetup.PageOrientation = XLPageOrientation.Landscape;
            ws.PageSetup.FitToPages(1, 0);
            ws.PageSetup.CenterHorizontally = true;

            ws.Columns(1, 10).AdjustToContents(1, 80); // solo columnas usadas por la tabla

            using var ms = new MemoryStream();
            wb.SaveAs(ms);
            return ms.ToArray();
        }

        private static void EscribirKpiCard(
            IXLWorksheet ws,
            int topRow,
            int colFrom,
            int colTo,
            string label,
            string value,
            XLColor bg,
            bool isMoney = false
        )
        {
            var rLabel = ws.Range(topRow, colFrom, topRow, colTo);
            rLabel.Merge();
            rLabel.FirstCell().Value = label;
            rLabel.Style.Font.FontColor = XLColor.FromHtml("#64748B"); // slate-500
            rLabel.Style.Font.FontSize = 9;
            rLabel.Style.Fill.BackgroundColor = bg;
            rLabel.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Left;

            var rVal = ws.Range(topRow + 1, colFrom, topRow + 1, colTo);
            rVal.Merge();
            rVal.FirstCell().Value = value;
            rVal.Style.Font.Bold = true;
            rVal.Style.Font.FontSize = 14;
            rVal.Style.Fill.BackgroundColor = bg;
            rVal.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Left;

            // borde tipo "card"
            var box = ws.Range(topRow, colFrom, topRow + 1, colTo);
            box.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
            box.Style.Border.OutsideBorderColor = XLColor.FromHtml("#CBD5E1"); // slate-300

            ws.Row(topRow).Height = 15;
            ws.Row(topRow + 1).Height = 22;
        }

        public byte[] GenerarExcelPagosPendientes(ReporteCxcViewModel vm)
        {
            using var wb = new XLWorkbook();
            var ws = wb.AddWorksheet("Pagos pendientes");

            ws.Style.Font.FontName = "Calibri";
            ws.Style.Font.FontSize = 11;

            const int MAX_COL = 18; // A..R
            int r = 1;

            // Paleta (misma linea sobria)
            var cTitle    = XLColor.FromHtml("#0F172A"); // slate-900
            var cTeal     = XLColor.FromHtml("#0F766E"); // teal-700
            var cBlueGray = XLColor.FromHtml("#1E293B"); // slate-800
            var cSlate    = XLColor.FromHtml("#334155"); // slate-700
            var cSoftGray = XLColor.FromHtml("#F1F5F9"); // slate-100
            var cZebra    = XLColor.FromHtml("#F8FAFC"); // zebra
            var cWarnRow  = XLColor.FromHtml("#FEF3C7"); // warning suave

            string ClienteNombre()
            {
                if (!vm.ClienteId.HasValue) return "Todos";
                return vm.Clientes.FirstOrDefault(x => x.Id == vm.ClienteId.Value)?.Nombre
                    ?? vm.ClienteId.Value.ToString();
            }

            string BucketNombre()
            {
                if (!vm.BucketId.HasValue) return "Todos";
                return vm.BucketId.Value switch
                {
                    0 => "No vencido",
                    1 => "1-7",
                    2 => "8-14",
                    3 => "15-30",
                    4 => "31-60",
                    5 => "61+",
                    _ => vm.BucketId.Value.ToString()
                };
            }

            // ------------------
            // TITULO
            // ------------------
            var title = ws.Range(r, 1, r, MAX_COL);
            title.Merge();
            title.FirstCell().Value = "Pagos pendientes";
            title.Style.Font.Bold = true;
            title.Style.Font.FontSize = 16;
            title.Style.Font.FontColor = XLColor.White;
            title.Style.Fill.BackgroundColor = cTitle;
            title.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            title.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Row(r).Height = 26;
            r++;

            var gen = ws.Range(r, 1, r, MAX_COL);
            gen.Merge();
            gen.FirstCell().Value = $"Generado: {DateTime.Now:yyyy-MM-dd HH:mm}";
            gen.Style.Font.FontSize = 9;
            gen.Style.Font.FontColor = XLColor.Gray;
            gen.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            r += 2;

            // ------------------
            // FILTROS
            // ------------------
            r = EscribirTituloSeccion(ws, r, "Filtros", cSlate, MAX_COL);

            var desde = vm.Desde?.ToString("yyyy-MM-dd");
            var hasta = vm.Hasta?.ToString("yyyy-MM-dd");
            var cliente = ClienteNombre();
            var pedido = vm.PedidoId?.ToString() ?? "-";
            var metodo = string.IsNullOrWhiteSpace(vm.Metodo) ? "-" : vm.Metodo.Trim();
            var bucket = BucketNombre();
            var minSaldo = vm.MinSaldo?.ToString("0.##") ?? "-";
            var soloVencidos = vm.SoloVencidos ? "Sí" : "No";

            // fila 1
            EscribirKVInline(ws, r,  1, "Desde",   desde,   2, 2, cSoftGray);
            EscribirKVInline(ws, r,  5, "Hasta",   hasta,   2, 2, cSoftGray);
            EscribirKVInline(ws, r,  9, "Cliente", cliente, 2, 4, cSoftGray);
            EscribirKVInline(ws, r, 15, "PedidoId",pedido,  2, 2, cSoftGray);
            r++;

            // fila 2
            EscribirKVInline(ws, r,  1, "Bucket",       bucket,      2, 2, cSoftGray);
            EscribirKVInline(ws, r,  5, "Min saldo",    minSaldo,    2, 2, cSoftGray);
            EscribirKVInline(ws, r,  9, "Método/Ref",   metodo,      2, 6, cSoftGray);
            EscribirKVInline(ws, r, 15, "Solo vencidos",soloVencidos,2, 2, cSoftGray);
            r += 2;

            // ------------------
            // KPIs
            // ------------------
            r = EscribirTituloSeccion(ws, r, "KPIs", cTeal, MAX_COL);

            EscribirKpiCard(ws, r,  1,  4, "Pedidos con saldo", vm.Totales.PedidosConSaldo.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r,  5,  8, "Saldo total",       (vm.Totales.SaldoTotal ?? 0m).ToString("N2"), cSoftGray, isMoney: true);
            EscribirKpiCard(ws, r,  9, 12, "Pedidos vencidos",  vm.Totales.PedidosVencidos.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r, 13, 18, "Saldo vencido",     (vm.Totales.SaldoVencido ?? 0m).ToString("N2"), cSoftGray, isMoney: true);

            // rojo si saldo vencido > 0
            if ((vm.Totales.SaldoVencido ?? 0m) > 0m)
                ws.Range(r + 1, 13, r + 1, 18).Style.Font.FontColor = XLColor.FromHtml("#B91C1C"); // red-700

            r += 3;

            // ------------------
            // BUCKETS
            // ------------------
            r = EscribirTituloSeccion(ws, r, "Buckets de vencimiento", cBlueGray, MAX_COL);

            var dtBuckets = new DataTable("Buckets");
            dtBuckets.Columns.Add("Bucket");
            dtBuckets.Columns.Add("Pedidos", typeof(int));
            dtBuckets.Columns.Add("Saldo", typeof(decimal));

            foreach (var b in vm.Buckets)
            {
                dtBuckets.Rows.Add(
                    b.BucketNombre,
                    b.Pedidos,
                    (b.Saldo ?? 0m)
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtBuckets, "tblCxcBuckets", cBlueGray, MAX_COL, cZebra, out var tblBuckets) + 2;

            if (tblBuckets != null)
            {
                AplicarFormatosTabla(tblBuckets, new()
                {
                    ["Saldo"] = "#,##0.00;[Red]-#,##0.00",
                });

                foreach (var name in new[] { "Pedidos", "Saldo" })
                {
                    if (!TieneCampo(tblBuckets, name)) continue;
                    var pos = ObtenerPosCampo1Based(tblBuckets, name);
                    var rng = ObtenerRangoDatosColumna(tblBuckets, pos);
                    rng.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Right;
                }
            }

            // ------------------
            // DETALLE
            // ------------------
            r = EscribirTituloSeccion(ws, r, "Detalle (pedidos con saldo)", cBlueGray, MAX_COL);

            var dt = new DataTable("Detalle");
            dt.Columns.Add("Pedido", typeof(int));
            dt.Columns.Add("Cliente");
            dt.Columns.Add("Estatus");
            dt.Columns.Add("Fecha base", typeof(DateTime));
            dt.Columns.Add("Días", typeof(int));
            dt.Columns.Add("Bucket");
            dt.Columns.Add("Total", typeof(decimal));
            dt.Columns.Add("Pagado", typeof(decimal));
            dt.Columns.Add("Saldo", typeof(decimal));
            dt.Columns.Add("Pagado %", typeof(decimal)); // ratio 0..1
            dt.Columns.Add("Último pago", typeof(DateTime));
            dt.Columns.Add("Método");

            foreach (var x in vm.Rows
                .OrderByDescending(x => x.DiasVencidos)
                .ThenByDescending(x => x.Saldo)
                .ThenBy(x => x.PedidoId))
            {
                var pctRaw = x.PagadoPct;                 // en tu UI lo pintas como 0..100
                var pct = pctRaw > 1m ? pctRaw / 100m : pctRaw;

                dt.Rows.Add(
                    x.PedidoId,
                    x.ClienteNombre ?? "-",
                    x.PedidoEstatusNombre ?? "-",
                    x.FechaBase.Date,
                    x.DiasVencidos,
                    x.BucketNombre,
                    x.TotalCobro,
                    x.TotalPagado,
                    x.Saldo,
                    pct,
                    x.UltimoPagoFecha.HasValue ? x.UltimoPagoFecha.Value.Date : DBNull.Value,
                    (x.UltimoPagoMetodo ?? x.UltimoPagoTipoNombre ?? "-")
                );
            }

            var lastRow = InsertarTablaAt(ws, r, 1, dt, "tblCxcDetalle", cBlueGray, MAX_COL, cZebra, out var tbl);

            if (tbl != null)
            {
                AplicarFormatosTabla(tbl, new()
                {
                    ["Total"]    = "#,##0.00",
                    ["Pagado"]   = "#,##0.00",
                    ["Saldo"]    = "#,##0.00;[Red]-#,##0.00",
                    ["Pagado %"] = "0.00%",
                    ["Días"]     = "0",
                });

                // fechas
                foreach (var field in new[] { "Fecha base", "Último pago" })
                {
                    if (!TieneCampo(tbl, field)) continue;
                    var pos = ObtenerPosCampo1Based(tbl, field);
                    var rng = ObtenerRangoDatosColumna(tbl, pos);
                    rng.Style.DateFormat.Format = "yyyy-mm-dd";
                    rng.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                }

                // resaltar vencidos (fila completa) si Dias > 0
                if (tbl.DataRange != null && TieneCampo(tbl, "Días"))
                {
                    var posDias = ObtenerPosCampo1Based(tbl, "Días");
                    var dr = tbl.DataRange;

                    for (int i = 1; i <= dr.RowCount(); i++)
                    {
                        var dias = dr.Row(i).Cell(posDias).GetValue<int>();
                        if (dias > 0)
                            dr.Row(i).Style.Fill.BackgroundColor = cWarnRow;
                    }
                }

                // freeze dejando arriba titulo + filtros + kpis + buckets
                ws.SheetView.FreezeRows(tbl.RangeAddress.FirstAddress.RowNumber);

                // anchos minimos utiles
                ws.Column(2).Width = Math.Max(ws.Column(2).Width, 26); // Cliente
                ws.Column(3).Width = Math.Max(ws.Column(3).Width, 14); // Estatus
                ws.Column(6).Width = Math.Max(ws.Column(6).Width, 12); // Bucket
                ws.Column(12).Width = Math.Max(ws.Column(12).Width, 18); // Método
            }

            r = lastRow + 2;

            // Nota final
            var note = ws.Range(r, 1, r, MAX_COL);
            note.Merge();
            note.FirstCell().Value = "* Fecha base = Vigencia cotización > Fecha creación cotización > Fecha creación pedido.";
            note.Style.Font.FontSize = 9;
            note.Style.Font.FontColor = XLColor.Gray;

            // ajustes finales
            ws.PageSetup.PageOrientation = XLPageOrientation.Landscape;
            ws.PageSetup.FitToPages(1, 0);
            ws.PageSetup.CenterHorizontally = true;

            ws.Columns(1, 12).AdjustToContents(1, 80);

            using var ms = new MemoryStream();
            wb.SaveAs(ms);
            return ms.ToArray();
        }
        public byte[] GenerarExcelCotizacionesSeguimiento(ReporteCotizacionesSeguimientoViewModel vm)
        {
            using var wb = new XLWorkbook();
            var ws = wb.AddWorksheet("Cotizaciones");

            ws.Style.Font.FontName = "Calibri";
            ws.Style.Font.FontSize = 11;

            const int MAX_COL = 18; // A..R
            int r = 1;

            // Paleta sobria (igual familia que los demás)
            var cTitle    = XLColor.FromHtml("#0F172A"); // slate-900
            var cTeal     = XLColor.FromHtml("#0F766E"); // teal-700
            var cPurple   = XLColor.FromHtml("#5B21B6"); // violet-800
            var cBlueGray = XLColor.FromHtml("#1E293B"); // slate-800
            var cSlate    = XLColor.FromHtml("#334155"); // slate-700
            var cSoftGray = XLColor.FromHtml("#F1F5F9"); // slate-100
            var cZebra    = XLColor.FromHtml("#F8FAFC"); // zebra

            // resaltados suaves por categoría
            var cOkRow    = XLColor.FromHtml("#ECFDF5"); // green-50
            var cWarnRow  = XLColor.FromHtml("#FEF3C7"); // amber-100
            var cBadRow   = XLColor.FromHtml("#FEE2E2"); // red-100
            var cGrayRow  = XLColor.FromHtml("#F1F5F9"); // slate-100

            string NombreLookup(List<SimpleOption> list, int? id)
            {
                if (!id.HasValue) return "Todos";
                return list.FirstOrDefault(x => x.Id == id.Value)?.Nombre ?? id.Value.ToString();
            }

            // ----------------
            // Titulo
            // ----------------
            var title = ws.Range(r, 1, r, MAX_COL);
            title.Merge();
            title.FirstCell().Value = "Cotizaciones — Conversión y seguimiento";
            title.Style.Font.Bold = true;
            title.Style.Font.FontSize = 16;
            title.Style.Font.FontColor = XLColor.White;
            title.Style.Fill.BackgroundColor = cTitle;
            title.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            title.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Row(r).Height = 26;
            r++;

            var gen = ws.Range(r, 1, r, MAX_COL);
            gen.Merge();
            gen.FirstCell().Value = $"Generado: {DateTime.Now:yyyy-MM-dd HH:mm}";
            gen.Style.Font.FontSize = 9;
            gen.Style.Font.FontColor = XLColor.Gray;
            gen.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            r += 2;

            // ----------------
            // Filtros
            // ----------------
            r = EscribirTituloSeccion(ws, r, "Filtros", cSlate, MAX_COL);

            var fDesde = vm.Desde.ToString("yyyy-MM-dd");
            var fHasta = vm.Hasta.ToString("yyyy-MM-dd");
            var fCliente = NombreLookup(vm.Clientes, vm.ClienteId);
            var fEstatus = NombreLookup(vm.Estatus, vm.CotizacionEstatusId);
            var fSoloConv = vm.SoloConvertidas ? "Sí" : "No";
            var fSoloUltima = vm.SoloUltimaPorPedido ? "Sí" : "No";
            var fMinMonto = vm.MinMonto?.ToString("0.##") ?? "-";
            var fQ = string.IsNullOrWhiteSpace(vm.Q) ? "-" : vm.Q.Trim();

            // fila 1
            EscribirKVInline(ws, r,  1, "Desde",   fDesde,   2, 2, cSoftGray); // 1..4
            EscribirKVInline(ws, r,  5, "Hasta",   fHasta,   2, 2, cSoftGray); // 5..8
            EscribirKVInline(ws, r,  9, "Cliente", fCliente, 2, 4, cSoftGray); // 9..14
            EscribirKVInline(ws, r, 15, "Estatus", fEstatus, 2, 2, cSoftGray); // 15..18
            r++;

            // fila 2
            EscribirKVInline(ws, r,  1, "Solo conv.",  fSoloConv,   2, 2, cSoftGray); // 1..4
            EscribirKVInline(ws, r,  5, "Solo última", fSoloUltima, 2, 2, cSoftGray); // 5..8
            EscribirKVInline(ws, r,  9, "Min monto",   fMinMonto,   2, 2, cSoftGray); // 9..12
            EscribirKVInline(ws, r, 13, "Buscar",      fQ,          2, 4, cSoftGray); // 13..18
            r += 2;

            // ----------------
            // KPIs (cards)
            // ----------------
            r = EscribirTituloSeccion(ws, r, "KPIs", cTeal, MAX_COL);

            // 1era fila (5 cards)
            EscribirKpiCard(ws, r,  1,  3, "Cotizaciones", vm.Totales.Cotizaciones.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r,  4,  6, "Convertidas",  vm.Totales.Convertidas.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r,  7,  9, "Conversión %", $"{(vm.Totales.ConversionPct ?? 0):N2}%", cSoftGray);
            EscribirKpiCard(ws, r, 10, 13, "Monto total",  $"{(vm.Totales.MontoTotal ?? 0):N2}", cSoftGray);
            EscribirKpiCard(ws, r, 14, 18, "Avg días conv.", $"{(vm.Totales.AvgDiasAConversion ?? 0):N1}", cSoftGray);

            r += 3;

            // 2da fila (3 cards)
            EscribirKpiCard(ws, r,  1,  6, "Aceptadas",  vm.Totales.Aceptadas.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r,  7, 12, "Pendientes", vm.Totales.Pendientes.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r, 13, 18, "Rechazadas", vm.Totales.Rechazadas.ToString("N0"), cSoftGray);

            r += 3;

            // ----------------
            // Resumen por estatus
            // ----------------
            r = EscribirTituloSeccion(ws, r, "Resumen por estatus", cPurple, MAX_COL);

            var dtResumen = new DataTable("ResumenEstatus");
            dtResumen.Columns.Add("Estatus");
            dtResumen.Columns.Add("Cotizaciones", typeof(int));
            dtResumen.Columns.Add("Monto", typeof(decimal));
            dtResumen.Columns.Add("Convertidas", typeof(int));
            dtResumen.Columns.Add("Conversión %", typeof(decimal)); // ratio 0..1

            foreach (var x in vm.PorEstatus.OrderBy(x => x.CotizacionEstatusNombre))
            {
                var pctRaw = x.ConversionPct ?? 0m;
                var pct = pctRaw > 1m ? pctRaw / 100m : pctRaw;

                dtResumen.Rows.Add(
                    x.CotizacionEstatusNombre,
                    x.Cotizaciones,
                    x.Monto ?? 0m,
                    x.Convertidas,
                    pct
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtResumen, "tblCotResumen", cPurple, MAX_COL, cZebra, out var tblResumen) + 2;

            if (tblResumen != null)
            {
                AplicarFormatosTabla(tblResumen, new()
                {
                    ["Monto"] = "#,##0.00",
                    ["Conversión %"] = "0.00%",
                });

                // alineación
                foreach (var name in new[] { "Cotizaciones", "Monto", "Convertidas", "Conversión %" })
                {
                    if (!TieneCampo(tblResumen, name)) continue;
                    var pos = ObtenerPosCampo1Based(tblResumen, name);
                    var rng = ObtenerRangoDatosColumna(tblResumen, pos);
                    rng.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Right;
                }
            }

            // ----------------
            // Detalle
            // ----------------
            r = EscribirTituloSeccion(ws, r, "Detalle", cBlueGray, MAX_COL);

            var dtDet = new DataTable("DetalleCotizaciones");
            dtDet.Columns.Add("Cotización", typeof(int));
            dtDet.Columns.Add("Pedido", typeof(int));
            dtDet.Columns.Add("Cliente");
            dtDet.Columns.Add("Estatus");
            dtDet.Columns.Add("Categoría");
            dtDet.Columns.Add("Fecha", typeof(DateTime));
            dtDet.Columns.Add("Monto", typeof(decimal));
            dtDet.Columns.Add("Pagado", typeof(decimal));
            dtDet.Columns.Add("Saldo", typeof(decimal));
            dtDet.Columns.Add("Último pago", typeof(DateTime));
            dtDet.Columns.Add("Método");
            dtDet.Columns.Add("Conv");
            dtDet.Columns.Add("Días", typeof(int));

            foreach (var x in vm.Rows
                .OrderByDescending(x => x.CotizacionFechaCreacion)
                .ThenByDescending(x => x.CotizacionId))
            {
                dtDet.Rows.Add(
                    x.CotizacionId,
                    x.PedidoId,
                    x.ClienteNombre ?? "-",
                    x.CotizacionEstatusNombre ?? "-",
                    x.Categoria ?? "-",
                    x.CotizacionFechaCreacion.Date,
                    x.MontoCotizacion,
                    x.TotalPagado,
                    x.Saldo,
                    x.UltimoPagoFecha.HasValue ? x.UltimoPagoFecha.Value.Date : DBNull.Value,
                    (x.UltimoPagoTipoNombre ?? x.UltimoPagoMetodo ?? "-"),
                    x.Convertida ? "Sí" : "No",
                    x.DiasAConversion ?? (object)DBNull.Value
                );
            }

            var lastRow = InsertarTablaAt(ws, r, 1, dtDet, "tblCotDetalle", cBlueGray, MAX_COL, cZebra, out var tblDet);

            if (tblDet != null)
            {
                AplicarFormatosTabla(tblDet, new()
                {
                    ["Monto"] = "#,##0.00",
                    ["Pagado"] = "#,##0.00",
                    ["Saldo"] = "#,##0.00;[Red]-#,##0.00",
                });

                // fechas
                foreach (var name in new[] { "Fecha", "Último pago" })
                {
                    if (!TieneCampo(tblDet, name)) continue;
                    var pos = ObtenerPosCampo1Based(tblDet, name);
                    var rng = ObtenerRangoDatosColumna(tblDet, pos);
                    rng.Style.DateFormat.Format = "yyyy-mm-dd";
                    rng.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                }

                // resaltar por categoría (fila completa)
                if (tblDet.DataRange != null && TieneCampo(tblDet, "Categoría"))
                {
                    var posCat = ObtenerPosCampo1Based(tblDet, "Categoría");
                    var dr = tblDet.DataRange;

                    for (int i = 1; i <= dr.RowCount(); i++)
                    {
                        var cat = dr.Row(i).Cell(posCat).GetString();

                        if (cat.Equals("Aceptada", StringComparison.OrdinalIgnoreCase))
                            dr.Row(i).Style.Fill.BackgroundColor = cOkRow;
                        else if (cat.Equals("Pendiente", StringComparison.OrdinalIgnoreCase))
                            dr.Row(i).Style.Fill.BackgroundColor = cWarnRow;
                        else if (cat.Equals("Rechazada", StringComparison.OrdinalIgnoreCase))
                            dr.Row(i).Style.Fill.BackgroundColor = cBadRow;
                        else
                            dr.Row(i).Style.Fill.BackgroundColor = cGrayRow;
                    }
                }

                // Conv = Sí en verde suave (columna)
                if (TieneCampo(tblDet, "Conv") && tblDet.DataRange != null)
                {
                    var posConv = ObtenerPosCampo1Based(tblDet, "Conv");
                    var rngConv = ObtenerRangoDatosColumna(tblDet, posConv);

                    rngConv.AddConditionalFormat()
                        .WhenEquals("Sí")
                        .Fill.SetBackgroundColor(cOkRow);
                }

                // freeze hasta el header de detalle (para que queden filtros + KPIs)
                ws.SheetView.FreezeRows(tblDet.RangeAddress.FirstAddress.RowNumber);

                // anchos minimos útiles
                ws.Column(3).Width = Math.Max(ws.Column(3).Width, 26);  // Cliente
                ws.Column(4).Width = Math.Max(ws.Column(4).Width, 16);  // Estatus
                ws.Column(5).Width = Math.Max(ws.Column(5).Width, 12);  // Categoría
                ws.Column(11).Width = Math.Max(ws.Column(11).Width, 18); // Método
            }

            // Ajustes finales
            ws.PageSetup.PageOrientation = XLPageOrientation.Landscape;
            ws.PageSetup.FitToPages(1, 0);
            ws.PageSetup.CenterHorizontally = true;

            ws.Columns(1, 13).AdjustToContents(1, 80);

            using var ms = new MemoryStream();
            wb.SaveAs(ms);
            return ms.ToArray();
        }

        public byte[] GenerarExcelProduccionUtilizacion(ReporteProduccionUtilizacionViewModel vm)
        {
            using var wb = new XLWorkbook();
            var ws = wb.AddWorksheet("Utilización");

            ws.Style.Font.FontName = "Calibri";
            ws.Style.Font.FontSize = 11;

            const int MAX_COL = 18; // A..R
            int r = 1;

            // Paleta sobria (igual familia que tus otros reportes)
            var cTitle    = XLColor.FromHtml("#0F172A"); // slate-900
            var cTeal     = XLColor.FromHtml("#0F766E"); // teal-700
            var cPurple   = XLColor.FromHtml("#5B21B6"); // violet-800
            var cBlueGray = XLColor.FromHtml("#1E293B"); // slate-800
            var cSlate    = XLColor.FromHtml("#334155"); // slate-700
            var cSoftGray = XLColor.FromHtml("#F1F5F9"); // slate-100
            var cZebra    = XLColor.FromHtml("#F8FAFC"); // zebra
            var cWarnRow  = XLColor.FromHtml("#FEF3C7"); // warning suave
            var cOkRow    = XLColor.FromHtml("#ECFDF5"); // green suave

            string fmtDate(DateTime? d) => d.HasValue ? d.Value.ToString("yyyy-MM-dd") : "-";
            string fmtHours(decimal h) => h.ToString("0.00");
            string fmtMin(decimal m) => m.ToString("0.0");

            string NombreImpresora(int? id)
            {
                if (!id.HasValue) return "(Sin impresora)";
                var it = vm.CatImpresoras?.FirstOrDefault(x => x.Id == id.Value);
                if (it == null) return id.Value.ToString();
                return string.IsNullOrWhiteSpace(it.Modelo) ? it.Nombre : $"{it.Nombre} ({it.Modelo})";
            }

            // ----------------
            // Titulo
            // ----------------
            var title = ws.Range(r, 1, r, MAX_COL);
            title.Merge();
            title.FirstCell().Value = "Producción — Utilización por impresora";
            title.Style.Font.Bold = true;
            title.Style.Font.FontSize = 16;
            title.Style.Font.FontColor = XLColor.White;
            title.Style.Fill.BackgroundColor = cTitle;
            title.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            title.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Row(r).Height = 26;
            r++;

            var gen = ws.Range(r, 1, r, MAX_COL);
            gen.Merge();
            gen.FirstCell().Value = $"Generado: {DateTime.Now:yyyy-MM-dd HH:mm}";
            gen.Style.Font.FontSize = 9;
            gen.Style.Font.FontColor = XLColor.Gray;
            gen.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            r += 2;

            // ----------------
            // Filtros
            // ----------------
            r = EscribirTituloSeccion(ws, r, "Filtros", cSlate, MAX_COL);

            var fDesde = fmtDate(vm.Desde);
            var fHasta = fmtDate(vm.Hasta);
            var fImp = vm.ImpresoraId.HasValue ? NombreImpresora(vm.ImpresoraId) : "Todas";
            var fQ = string.IsNullOrWhiteSpace(vm.Q) ? "-" : vm.Q.Trim();
            var fEnCurso = vm.IncluirEnCurso ? "Sí" : "No";
            var fSinImp = vm.IncluirSinImpresora ? "Sí" : "No";

            // fila 1
            EscribirKVInline(ws, r,  1, "Desde",     fDesde, 2, 2, cSoftGray); // 1..4
            EscribirKVInline(ws, r,  5, "Hasta",     fHasta, 2, 2, cSoftGray); // 5..8
            EscribirKVInline(ws, r,  9, "Impresora", fImp,   2, 4, cSoftGray); // 9..14
            EscribirKVInline(ws, r, 15, "Buscar",    fQ,     2, 2, cSoftGray); // 15..18
            r++;

            // fila 2
            EscribirKVInline(ws, r,  1, "Incluir curso", fEnCurso, 2, 2, cSoftGray); // 1..4
            EscribirKVInline(ws, r,  5, "Incl. sin imp", fSinImp,  2, 2, cSoftGray); // 5..8
            r += 2;

            // ----------------
            // KPIs (cards)
            // ----------------
            r = EscribirTituloSeccion(ws, r, "KPIs", cTeal, MAX_COL);

            EscribirKpiCard(ws, r,  1,  4, "Horas completadas", fmtHours(vm.Totales.HorasCompletadas), cSoftGray);
            EscribirKpiCard(ws, r,  5,  8, "Horas en curso",    fmtHours(vm.Totales.HorasEnCurso), cSoftGray);
            EscribirKpiCard(ws, r,  9, 12, "Items (total)",     vm.Totales.Items.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r, 13, 18, "Duración prom (min)", $"{fmtMin(vm.Totales.AvgDuracionMin)}", cSoftGray);

            r += 3;

            // fila kpi extra (texto compacto)
            EscribirKpiCard(ws, r,  1,  6, "Items completados", vm.Totales.ItemsCompletados.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r,  7, 12, "Items en curso",    vm.Totales.ItemsEnCurso.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r, 13, 18, "Sin tiempos",       vm.Totales.ItemsSinTiempos.ToString("N0"), cSoftGray);

            r += 3;

            // ----------------
            // Tabla: Utilización por impresora
            // ----------------
            r = EscribirTituloSeccion(ws, r, "Utilización por impresora", cPurple, MAX_COL);

            var dtImp = new DataTable("PorImpresora");
            dtImp.Columns.Add("Impresora");
            dtImp.Columns.Add("Horas (total)", typeof(decimal));
            dtImp.Columns.Add("Horas compl.", typeof(decimal));
            dtImp.Columns.Add("Horas curso", typeof(decimal));
            dtImp.Columns.Add("Items", typeof(int));
            dtImp.Columns.Add("Compl.", typeof(int));
            dtImp.Columns.Add("Curso", typeof(int));
            dtImp.Columns.Add("Avg min", typeof(decimal));
            dtImp.Columns.Add("Fallas", typeof(int));
            dtImp.Columns.Add("Reimp", typeof(int));
            dtImp.Columns.Add("Sin tiempos", typeof(int));

            foreach (var x in vm.PorImpresora
                .OrderByDescending(x => x.HorasTotales)
                .ThenByDescending(x => x.Items)
                .ThenBy(x => x.ImpresoraNombre))
            {
                var nombre = x.ImpresoraId.HasValue
                    ? (string.IsNullOrWhiteSpace(x.ImpresoraModelo)
                        ? (x.ImpresoraNombre ?? x.ImpresoraId.Value.ToString())
                        : $"{x.ImpresoraNombre} ({x.ImpresoraModelo})")
                    : "(Sin impresora)";

                dtImp.Rows.Add(
                    nombre,
                    x.HorasTotales,
                    x.HorasCompletadas,
                    x.HorasEnCurso,
                    x.Items,
                    x.ItemsCompletados,
                    x.ItemsEnCurso,
                    x.AvgDuracionMin,
                    x.Fallas,
                    x.Reimpresiones,
                    x.ItemsSinTiempos
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtImp, "tblUtilImp", cPurple, MAX_COL, cZebra, out var tblImp) + 2;

            if (tblImp != null)
            {
                AplicarFormatosTabla(tblImp, new()
                {
                    ["Horas (total)"] = "#,##0.00",
                    ["Horas compl."]  = "#,##0.00",
                    ["Horas curso"]   = "#,##0.00",
                    ["Avg min"]       = "#,##0.0",
                });

                // resaltar fallas/reimp/sin tiempos (suave)
                if (tblImp.DataRange != null)
                {
                    var dr = tblImp.DataRange;

                    int posFallas = TieneCampo(tblImp, "Fallas") ? ObtenerPosCampo1Based(tblImp, "Fallas") : 0;
                    int posReimp  = TieneCampo(tblImp, "Reimp") ? ObtenerPosCampo1Based(tblImp, "Reimp") : 0;
                    int posSin    = TieneCampo(tblImp, "Sin tiempos") ? ObtenerPosCampo1Based(tblImp, "Sin tiempos") : 0;

                    for (int i = 1; i <= dr.RowCount(); i++)
                    {
                        bool warn = false;

                        if (posFallas > 0 && dr.Row(i).Cell(posFallas).GetValue<int>() > 0) warn = true;
                        if (posReimp  > 0 && dr.Row(i).Cell(posReimp).GetValue<int>() > 0) warn = true;
                        if (posSin    > 0 && dr.Row(i).Cell(posSin).GetValue<int>() > 0) warn = true;

                        if (warn) dr.Row(i).Style.Fill.BackgroundColor = cWarnRow;
                    }
                }

                // ancho util impresora
                ws.Column(1).Width = Math.Max(ws.Column(1).Width, 28);
            }

            // ----------------
            // Tabla: Detalle
            // ----------------
            r = EscribirTituloSeccion(ws, r, "Detalle", cBlueGray, MAX_COL);

            var dtDet = new DataTable("Detalle");
            dtDet.Columns.Add("ProdItem", typeof(int));
            dtDet.Columns.Add("Pedido", typeof(int));
            dtDet.Columns.Add("Cliente");
            dtDet.Columns.Add("Producto");
            dtDet.Columns.Add("Impresora");
            dtDet.Columns.Add("Inicio");
            dtDet.Columns.Add("Fin");
            dtDet.Columns.Add("Min", typeof(decimal));
            dtDet.Columns.Add("Estatus");
            dtDet.Columns.Add("Falla");
            dtDet.Columns.Add("Reimp");

            foreach (var x in vm.Detalle
                .OrderByDescending(x => x.FechaInicio ?? DateTime.MinValue)
                .ThenByDescending(x => x.ProduccionItemId))
            {
                dtDet.Rows.Add(
                    x.ProduccionItemId,
                    x.PedidoId,
                    x.ClienteNombre ?? "-",
                    x.ProductoNombre ?? "-",
                    x.ImpresoraNombre ?? "(Sin impresora)",
                    x.FechaInicio?.ToString("yyyy-MM-dd HH:mm") ?? "-",
                    x.FechaFin?.ToString("yyyy-MM-dd HH:mm") ?? "-",
                    x.DuracionMin,
                    x.ProduccionEstatusNombre ?? "-",
                    x.MarcadaFalla ? "Sí" : "No",
                    x.EsReimpresion ? "Sí" : "No"
                );
            }

            var last = InsertarTablaAt(ws, r, 1, dtDet, "tblUtilDetalle", cBlueGray, MAX_COL, cZebra, out var tblDet);

            if (tblDet != null)
            {
                AplicarFormatosTabla(tblDet, new()
                {
                    ["Min"] = "#,##0",
                });

                // resaltar filas con Falla/Reimp
                if (tblDet.DataRange != null)
                {
                    var dr = tblDet.DataRange;

                    int posFalla = TieneCampo(tblDet, "Falla") ? ObtenerPosCampo1Based(tblDet, "Falla") : 0;
                    int posReimp = TieneCampo(tblDet, "Reimp") ? ObtenerPosCampo1Based(tblDet, "Reimp") : 0;

                    for (int i = 1; i <= dr.RowCount(); i++)
                    {
                        var falla = posFalla > 0 ? dr.Row(i).Cell(posFalla).GetString() : "";
                        var reimp = posReimp > 0 ? dr.Row(i).Cell(posReimp).GetString() : "";

                        if (falla.Equals("Sí", StringComparison.OrdinalIgnoreCase) ||
                            reimp.Equals("Sí", StringComparison.OrdinalIgnoreCase))
                        {
                            dr.Row(i).Style.Fill.BackgroundColor = cWarnRow;
                        }
                    }
                }

                // Convierte estatus "Entregado" a verde suave (si existe)
                if (tblDet.DataRange != null && TieneCampo(tblDet, "Estatus"))
                {
                    var posEst = ObtenerPosCampo1Based(tblDet, "Estatus");
                    var rngEst = ObtenerRangoDatosColumna(tblDet, posEst);

                    rngEst.AddConditionalFormat()
                        .WhenEquals("Entregado")
                        .Fill.SetBackgroundColor(cOkRow);
                }

                // freeze hasta header de detalle
                ws.SheetView.FreezeRows(tblDet.RangeAddress.FirstAddress.RowNumber);

                // anchos mínimos utiles
                ws.Column(3).Width = Math.Max(ws.Column(3).Width, 22); // Cliente
                ws.Column(4).Width = Math.Max(ws.Column(4).Width, 22); // Producto
                ws.Column(5).Width = Math.Max(ws.Column(5).Width, 22); // Impresora
                ws.Column(6).Width = Math.Max(ws.Column(6).Width, 18); // Inicio
                ws.Column(7).Width = Math.Max(ws.Column(7).Width, 18); // Fin
            }

            // Ajustes finales
            ws.PageSetup.PageOrientation = XLPageOrientation.Landscape;
            ws.PageSetup.FitToPages(1, 0);
            ws.PageSetup.CenterHorizontally = true;

            ws.Columns(1, 11).AdjustToContents(1, 80);

            using var ms = new MemoryStream();
            wb.SaveAs(ms);
            return ms.ToArray();
        }

        public byte[] GenerarExcelInventarioConsumoMejorado(ReporteInventarioConsumoMejoradoViewModel vm)
        {
            using var wb = new XLWorkbook();
            var ws = wb.AddWorksheet("Consumo inventario");

            ws.Style.Font.FontName = "Calibri";
            ws.Style.Font.FontSize = 11;

            const int MAX_COL = 24; // A..X (porque va MUCHA data)
            int r = 1;

            // Paleta sobria (misma vibra que Pedido360)
            var cTitle    = XLColor.FromHtml("#0F172A"); // slate-900
            var cTeal     = XLColor.FromHtml("#0F766E"); // teal-700
            var cPurple   = XLColor.FromHtml("#5B21B6"); // violet-800
            var cOrange   = XLColor.FromHtml("#9A3412"); // orange-800
            var cGreen    = XLColor.FromHtml("#166534"); // green-800
            var cBlueGray = XLColor.FromHtml("#1E293B"); // slate-800
            var cSlate    = XLColor.FromHtml("#334155"); // slate-700
            var cSoftGray = XLColor.FromHtml("#F1F5F9"); // slate-100
            var cZebra    = XLColor.FromHtml("#F8FAFC"); // zebra

            string MoneyFmt = "#,##0.00";
            string MoneyFmtRed = "#,##0.00;[Red]-#,##0.00";

            // ---------- lookups ----------
            string LookupNombre<T>(List<T> list, int? id, Func<T, int> getId, Func<T, string> getName, string fallbackTodos = "Todos")
            {
                if (!id.HasValue) return fallbackTodos;
                var item = list.FirstOrDefault(x => getId(x) == id.Value);
                return item == null ? id.Value.ToString() : getName(item);
            }

            string Safe(string? s) => string.IsNullOrWhiteSpace(s) ? "-" : s.Trim();

            // ---------- tarifas por renglon ----------
            string BuildTarifasDetalle(ReporteInventarioConsumoDetalleDto x)
            {
                var keyInsumo = $"{x.ProduccionItemId}|{x.InventarioId}";
                var keyGlobal = $"{x.ProduccionItemId}|0";

                vm.TarifasPorKey.TryGetValue(keyInsumo, out var tInsumo);
                vm.TarifasPorKey.TryGetValue(keyGlobal, out var tGlobal);

                if ((tInsumo == null || tInsumo.Count == 0) && (tGlobal == null || tGlobal.Count == 0))
                    return "-";

                var lines = new List<string>();

                if (tInsumo != null && tInsumo.Count > 0)
                {
                    lines.Add("INSUMO:");
                    foreach (var t in tInsumo)
                    {
                        lines.Add($"• {t.ConceptoCodigo} · {t.TarifaNombre} | {t.Cantidad:0.####} x {t.MontoTarifa:0.00} = {t.Subtotal:0.00}");
                    }
                }

                if (tGlobal != null && tGlobal.Count > 0)
                {
                    lines.Add("GLOBAL (InventarioId=0):");
                    foreach (var t in tGlobal)
                    {
                        lines.Add($"• {t.ConceptoCodigo} · {t.TarifaNombre} | {t.Cantidad:0.####} x {t.MontoTarifa:0.00} = {t.Subtotal:0.00}");
                    }
                }

                return string.Join(Environment.NewLine, lines);
            }

            // ==========================
            // TITULO
            // ==========================
            var title = ws.Range(r, 1, r, MAX_COL);
            title.Merge();
            title.FirstCell().Value = "Consumo de inventario — Costeo por tarifas";
            title.Style.Font.Bold = true;
            title.Style.Font.FontSize = 16;
            title.Style.Font.FontColor = XLColor.White;
            title.Style.Fill.BackgroundColor = cTitle;
            title.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            title.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Row(r).Height = 26;
            r++;

            var gen = ws.Range(r, 1, r, MAX_COL);
            gen.Merge();
            gen.FirstCell().Value = $"Generado: {DateTime.Now:yyyy-MM-dd HH:mm}";
            gen.Style.Font.FontSize = 9;
            gen.Style.Font.FontColor = XLColor.Gray;
            gen.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            r += 2;

            // ==========================
            // FILTROS
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Filtros", cSlate, MAX_COL);

            var desdeStr = vm.Desde?.ToString("yyyy-MM-dd") ?? "-";
            var hastaStr = vm.Hasta?.ToString("yyyy-MM-dd") ?? "-";

            var productoNombre = LookupNombre(vm.CatProductos, vm.ProductoId, x => x.Id, x => x.Nombre);
            var recetaNombre   = LookupNombre(vm.CatRecetas, vm.RecetaId, x => x.Id, x => x.Nombre, fallbackTodos: "Todas");
            var insumoNombre   = LookupNombre(vm.CatInsumos, vm.InventarioId, x => x.Id, x => string.IsNullOrWhiteSpace(x.UnidadNombre) ? x.Nombre : $"{x.Nombre} ({x.UnidadNombre})");

            EscribirKVInline(ws, r, 1,  "Desde",     desdeStr,             2, 2, cSoftGray);
            EscribirKVInline(ws, r, 5,  "Hasta",     hastaStr,             2, 2, cSoftGray);
            EscribirKVInline(ws, r, 9,  "PedidoId",  vm.PedidoId?.ToString() ?? "-", 2, 2, cSoftGray);
            EscribirKVInline(ws, r, 13, "Periodo",   Safe(vm.Periodo),     2, 2, cSoftGray);
            EscribirKVInline(ws, r, 17, "TopN",      vm.TopN.ToString(),   2, 2, cSoftGray);
            r++;

            EscribirKVInline(ws, r, 1,  "Producto",  productoNombre, 2, 6, cSoftGray);
            EscribirKVInline(ws, r, 9,  "Receta",    recetaNombre,   2, 6, cSoftGray);
            EscribirKVInline(ws, r, 17, "Insumo",    insumoNombre,   2, 2, cSoftGray);
            r++;

            EscribirKVInline(ws, r, 1, "Buscar (q)", Safe(vm.Q), 2, 10, cSoftGray);
            r += 2;

            // ==========================
            // KPIs
            // ==========================
            r = EscribirTituloSeccion(ws, r, "KPIs", cTeal, MAX_COL);

            // 4 cards grandes (2 filas cada una)
            EscribirKpiCard(ws, r,  1,  6,  "Movimientos", vm.Totales.Movimientos.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r,  7,  12, "Costo insumos (tarifas)", vm.Totales.CostoInsumosEstimado.ToString("N2"), cSoftGray);
            EscribirKpiCard(ws, r,  13, 18, "Costo material (item)", vm.Totales.CostoMaterialTotal.ToString("N2"), cSoftGray);
            EscribirKpiCard(ws, r,  19, 24, "Venta items (est.)", vm.Totales.VentaItemsEstimada.ToString("N2"), cSoftGray);
            r += 3;

            // segunda fila de KPIs (texto)
            EscribirKVInline(ws, r, 1,  "Items",              vm.Totales.ProduccionItems.ToString("N0"), 2, 2, cSoftGray);
            EscribirKVInline(ws, r, 5,  "Cantidad total",     vm.Totales.CantidadTotal.ToString("0.####"), 2, 2, cSoftGray);
            EscribirKVInline(ws, r, 9,  "Global (material)",  vm.Totales.CostoMaterialGlobal.ToString("N2"), 2, 2, cSoftGray);
            EscribirKVInline(ws, r, 13, "Ratio costo/venta",  vm.Totales.RatioCostoSobreVentaItems?.ToString("0.0000") ?? "-", 2, 2, cSoftGray);
            r += 2;

            // ==========================
            // TOP INSUMOS
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Top insumos", cBlueGray, MAX_COL);

            var dtTop = new DataTable("TopInsumos");
            dtTop.Columns.Add("InventarioId", typeof(int));
            dtTop.Columns.Add("Insumo");
            dtTop.Columns.Add("Unidad");
            dtTop.Columns.Add("Cantidad", typeof(decimal));
            dtTop.Columns.Add("Costo (tarifas)", typeof(decimal));
            dtTop.Columns.Add("Pedidos", typeof(int));
            dtTop.Columns.Add("Productos", typeof(int));

            foreach (var x in vm.TopInsumos)
            {
                dtTop.Rows.Add(
                    x.InventarioId,
                    x.InsumoNombre,
                    x.UnidadNombre,
                    x.CantidadTotal,
                    x.CostoTotalEstimado,
                    x.Pedidos,
                    x.Productos
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtTop, "tblTopInsumos", cBlueGray, MAX_COL, cZebra, out var tblTop) + 2;
            AplicarFormatosTabla(tblTop, new()
            {
                ["Cantidad"] = "#,##0.####",
                ["Costo (tarifas)"] = MoneyFmt,
            });

            // ==========================
            // RESUMENES (Producto / Pedido / Receta / Periodo)
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Resúmenes", cPurple, MAX_COL);

            // --- Por producto ---
            var dtProd = new DataTable("PorProducto");
            dtProd.Columns.Add("ProductoId", typeof(int));
            dtProd.Columns.Add("Producto");
            dtProd.Columns.Add("Cantidad", typeof(decimal));
            dtProd.Columns.Add("Costo insumos", typeof(decimal));
            dtProd.Columns.Add("Costo material", typeof(decimal));
            dtProd.Columns.Add("Venta est.", typeof(decimal));
            dtProd.Columns.Add("Pedidos", typeof(int));
            dtProd.Columns.Add("ProdItems", typeof(int));
            dtProd.Columns.Add("Recetas", typeof(int));

            foreach (var x in vm.PorProducto)
            {
                dtProd.Rows.Add(
                    x.ProductoId,
                    x.ProductoNombre,
                    x.CantidadTotal ?? 0m,
                    x.CostoInsumosEstimado ?? 0m,
                    x.CostoMaterialTotal,
                    x.VentaItemsEstimada,
                    x.Pedidos,
                    x.ProduccionItems,
                    x.Recetas
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtProd, "tblPorProducto", cPurple, MAX_COL, cZebra, out var tblProd) + 1;
            AplicarFormatosTabla(tblProd, new()
            {
                ["Cantidad"] = "#,##0.####",
                ["Costo insumos"] = MoneyFmt,
                ["Costo material"] = MoneyFmt,
                ["Venta est."] = MoneyFmt,
            });

            r += 1;

            // --- Por pedido ---
            var dtPed = new DataTable("PorPedido");
            dtPed.Columns.Add("PedidoId", typeof(int));
            dtPed.Columns.Add("Cliente");
            dtPed.Columns.Add("Fecha", typeof(DateTime));
            dtPed.Columns.Add("Pedido total", typeof(decimal));
            dtPed.Columns.Add("Cantidad", typeof(decimal));
            dtPed.Columns.Add("Costo insumos", typeof(decimal));
            dtPed.Columns.Add("Costo material", typeof(decimal));
            dtPed.Columns.Add("Venta est.", typeof(decimal));
            dtPed.Columns.Add("Ratio costo/venta", typeof(decimal));

            foreach (var x in vm.PorPedido)
            {
                dtPed.Rows.Add(
                    x.PedidoId,
                    x.ClienteNombre,
                    x.PedidoFechaCreacion.Date,
                    x.PedidoTotalEstimado,
                    x.CantidadTotal ?? 0m,
                    x.CostoInsumosEstimado ?? 0m,
                    x.CostoMaterialTotal,
                    x.VentaItemsEstimada,
                    x.RatioCostoSobreVentaItems ?? 0m
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtPed, "tblPorPedido", cPurple, MAX_COL, cZebra, out var tblPed) + 1;
            AplicarFormatosTabla(tblPed, new()
            {
                ["Fecha"] = "yyyy-mm-dd",
                ["Pedido total"] = MoneyFmt,
                ["Cantidad"] = "#,##0.####",
                ["Costo insumos"] = MoneyFmt,
                ["Costo material"] = MoneyFmt,
                ["Venta est."] = MoneyFmt,
                ["Ratio costo/venta"] = "0.0000",
            });

            r += 1;

            // --- Por receta ---
            var dtRec = new DataTable("PorReceta");
            dtRec.Columns.Add("RecetaId");
            dtRec.Columns.Add("Receta");
            dtRec.Columns.Add("ProductoId", typeof(int));
            dtRec.Columns.Add("Producto");
            dtRec.Columns.Add("Cantidad", typeof(decimal));
            dtRec.Columns.Add("Costo insumos", typeof(decimal));
            dtRec.Columns.Add("Costo material", typeof(decimal));
            dtRec.Columns.Add("ProdItems", typeof(int));
            dtRec.Columns.Add("Pedidos", typeof(int));

            foreach (var x in vm.PorReceta)
            {
                dtRec.Rows.Add(
                    x.RecetaId?.ToString() ?? "-",
                    x.RecetaNombre,
                    x.ProductoId,
                    x.ProductoNombre,
                    x.CantidadTotal ?? 0m,
                    x.CostoInsumosEstimado ?? 0m,
                    x.CostoMaterialTotal,
                    x.ProduccionItems,
                    x.Pedidos
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtRec, "tblPorReceta", cPurple, MAX_COL, cZebra, out var tblRec) + 2;
            AplicarFormatosTabla(tblRec, new()
            {
                ["Cantidad"] = "#,##0.####",
                ["Costo insumos"] = MoneyFmt,
                ["Costo material"] = MoneyFmt,
            });

            // --- Top por periodo ---
            r = EscribirTituloSeccion(ws, r, "Top por periodo (insumo)", cSlate, MAX_COL);

            var dtPer = new DataTable("TopPorPeriodo");
            dtPer.Columns.Add("Periodo inicio", typeof(DateTime));
            dtPer.Columns.Add("InventarioId", typeof(int));
            dtPer.Columns.Add("Insumo");
            dtPer.Columns.Add("Unidad");
            dtPer.Columns.Add("Cantidad", typeof(decimal));
            dtPer.Columns.Add("Costo (tarifas)", typeof(decimal));

            foreach (var x in vm.TopPorPeriodo)
            {
                dtPer.Rows.Add(
                    x.PeriodoInicio.Date,
                    x.InventarioId,
                    x.InsumoNombre,
                    x.UnidadNombre,
                    x.CantidadTotal,
                    x.CostoTotalEstimado
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtPer, "tblTopPeriodo", cSlate, MAX_COL, cZebra, out var tblPer) + 2;
            AplicarFormatosTabla(tblPer, new()
            {
                ["Periodo inicio"] = "yyyy-mm-dd",
                ["Cantidad"] = "#,##0.####",
                ["Costo (tarifas)"] = MoneyFmt,
            });

            // ==========================
            // DETALLE (con tarifas por renglon)
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Detalle (con tarifas por renglón)", cBlueGray, MAX_COL);

            var dtDet = new DataTable("Detalle");
            dtDet.Columns.Add("ConsumoId", typeof(int));
            dtDet.Columns.Add("Fecha", typeof(DateTime));
            dtDet.Columns.Add("PedidoId", typeof(int));
            dtDet.Columns.Add("Cliente");
            dtDet.Columns.Add("PedidoItemId", typeof(int));
            dtDet.Columns.Add("ProdItemId", typeof(int));

            dtDet.Columns.Add("Producto");
            dtDet.Columns.Add("Receta");
            dtDet.Columns.Add("InventarioId", typeof(int));
            dtDet.Columns.Add("Insumo");
            dtDet.Columns.Add("Unidad");

            dtDet.Columns.Add("Cant.", typeof(decimal));
            dtDet.Columns.Add("Costo unit (tarifa)", typeof(decimal));
            dtDet.Columns.Add("Costo (tarifa)", typeof(decimal));

            dtDet.Columns.Add("Costo global", typeof(decimal));
            dtDet.Columns.Add("Total + global", typeof(decimal));
            dtDet.Columns.Add("Unit + global", typeof(decimal));

            dtDet.Columns.Add("Venta item", typeof(decimal));
            dtDet.Columns.Add("Notas");
            dtDet.Columns.Add("Tarifas (detalle)"); // <- AQUÍ VA TODO EL DESGLOSE

            foreach (var x in vm.Detalle.OrderByDescending(x => x.FechaConsumo))
            {
                dtDet.Rows.Add(
                    x.ProduccionInventarioConsumoId,
                    x.FechaConsumo,
                    x.PedidoId,
                    x.ClienteNombre,
                    x.PedidoItemId,
                    x.ProduccionItemId,
                    x.ProductoNombre,
                    string.IsNullOrWhiteSpace(x.RecetaNombre) ? "-" : x.RecetaNombre,
                    x.InventarioId,
                    x.InsumoNombre,
                    x.UnidadNombre,
                    x.CantidadConsumida,
                    x.CostoUnitarioActual,
                    x.CostoTotalEstimado,
                    x.CostoGlobalAplicado,
                    x.CostoTotalConGlobal,
                    x.CostoUnitarioConGlobal,
                    x.VentaItemEstimada,
                    x.Notas ?? "-",
                    BuildTarifasDetalle(x)
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtDet, "tblDetalleConsumo", cBlueGray, MAX_COL, cZebra, out var tblDet) + 2;

            AplicarFormatosTabla(tblDet, new()
            {
                ["Fecha"] = "yyyy-mm-dd HH:mm",
                ["Cant."] = "#,##0.####",
                ["Costo unit (tarifa)"] = MoneyFmt,
                ["Costo (tarifa)"] = MoneyFmtRed,
                ["Costo global"] = MoneyFmtRed,
                ["Total + global"] = MoneyFmtRed,
                ["Unit + global"] = MoneyFmt,
                ["Venta item"] = MoneyFmt,
            });

            // Wrap para Notas y Tarifas(detalle) + ancho comodo
            if (tblDet != null)
            {
                if (TieneCampo(tblDet, "Notas"))
                    tblDet.Field("Notas").Column.Style.Alignment.WrapText = true;

                if (tblDet != null && TieneCampo(tblDet, "Tarifas (detalle)"))
                {
                    // wrap dentro del rango de la tabla
                    tblDet.Field("Tarifas (detalle)").Column.Style.Alignment.WrapText = true;

                    // columna real en hoja = inicioTabla + (indexCampo - 1)
                    var colNum =
                        tblDet.RangeAddress.FirstAddress.ColumnNumber
                        + tblDet.Field("Tarifas (detalle)").Index - 1;

                    var col = ws.Column(colNum); // IXLColumn (aquí SI hay Width)
                    col.Width = Math.Max(col.Width, 60d);
                }

                ws.Column(4).Width = Math.Max(ws.Column(4).Width, 22);  // Cliente
                ws.Column(7).Width = Math.Max(ws.Column(7).Width, 22);  // Producto
                ws.Column(10).Width = Math.Max(ws.Column(10).Width, 22); // Insumo
            }

            // ==========================
            // TARIFAS RAW (para “si o si toda la data”)
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Tarifas (raw)", cOrange, MAX_COL);

            var dtTar = new DataTable("TarifasRaw");
            dtTar.Columns.Add("ProdItemId", typeof(int));
            dtTar.Columns.Add("InventarioId", typeof(int));
            dtTar.Columns.Add("Fecha costeo", typeof(DateTime));
            dtTar.Columns.Add("ProduccionCosteoId", typeof(int));
            dtTar.Columns.Add("ConceptoCodigo");
            dtTar.Columns.Add("ConceptoNombre");
            dtTar.Columns.Add("ConceptoUnidad");
            dtTar.Columns.Add("TarifaId", typeof(int));
            dtTar.Columns.Add("TarifaNombre");
            dtTar.Columns.Add("TarifaOrden", typeof(int));
            dtTar.Columns.Add("Cantidad", typeof(decimal));
            dtTar.Columns.Add("Monto", typeof(decimal));
            dtTar.Columns.Add("Subtotal", typeof(decimal));

            foreach (var t in vm.TarifasDetalle.OrderByDescending(x => x.FechaCosteo).ThenBy(x => x.ProduccionItemId))
            {
                dtTar.Rows.Add(
                    t.ProduccionItemId,
                    t.InventarioId,
                    t.FechaCosteo,
                    t.ProduccionCosteoId,
                    t.ConceptoCodigo,
                    t.ConceptoNombre,
                    t.ConceptoUnidad ?? "-",
                    t.TarifaId,
                    t.TarifaNombre,
                    t.TarifaOrden,
                    t.Cantidad,
                    t.MontoTarifa,
                    t.Subtotal
                );
            }

            r = InsertarTablaAt(ws, r, 1, dtTar, "tblTarifasRaw", cOrange, MAX_COL, cZebra, out var tblTar) + 2;
            AplicarFormatosTabla(tblTar, new()
            {
                ["Fecha costeo"] = "yyyy-mm-dd",
                ["Cantidad"] = "#,##0.####",
                ["Monto"] = MoneyFmt,
                ["Subtotal"] = MoneyFmt,
            });

            // Ajustes finales
            ws.SheetView.FreezeRows(3);
            ws.PageSetup.PageOrientation = XLPageOrientation.Landscape;
            ws.PageSetup.FitToPages(1, 0);
            ws.PageSetup.CenterHorizontally = true;

            ws.Columns(1, MAX_COL).AdjustToContents(1, 80);

            using var ms = new MemoryStream();
            wb.SaveAs(ms);
            return ms.ToArray();
        }

        public byte[] GenerarExcelComprasHistorico(ReporteComprasHistoricoVm vm)
        {
            using var wb = new XLWorkbook();
            var ws = wb.AddWorksheet("Compras histórico");

            ws.Style.Font.FontName = "Calibri";
            ws.Style.Font.FontSize = 11;

            const int MAX_COL = 24; // A..X (detalle trae varias columnas)
            int r = 1;

            // Paleta sobria (misma linea que el resto)
            var cTitle    = XLColor.FromHtml("#0F172A"); // slate-900
            var cTeal     = XLColor.FromHtml("#0F766E"); // teal-700
            var cBlueGray = XLColor.FromHtml("#1E293B"); // slate-800
            var cSlate    = XLColor.FromHtml("#334155"); // slate-700
            var cSoftGray = XLColor.FromHtml("#F1F5F9"); // slate-100
            var cZebra    = XLColor.FromHtml("#F8FAFC"); // zebra
            var cDangerBg = XLColor.FromHtml("#FEE2E2"); // red-100
            var cDangerTx = XLColor.FromHtml("#7F1D1D"); // red-900

            string MoneyFmt() => "$#,##0.00";
            string QtyFmt() => "#,##0.####";
            string Safe(string? s) => string.IsNullOrWhiteSpace(s) ? "-" : s.Trim();

            string NombreLookup(List<CatalogoDto> list, int? id)
            {
                if (!id.HasValue) return "Todos";
                return list.FirstOrDefault(x => x.Id == id.Value)?.Nombre ?? id.Value.ToString();
            }

            // ==========================
            // TITULO
            // ==========================
            var title = ws.Range(r, 1, r, MAX_COL);
            title.Merge();
            title.FirstCell().Value = "Compras — histórico";
            title.Style.Font.Bold = true;
            title.Style.Font.FontSize = 16;
            title.Style.Font.FontColor = XLColor.White;
            title.Style.Fill.BackgroundColor = cTitle;
            title.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            title.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
            ws.Row(r).Height = 26;
            r++;

            var gen = ws.Range(r, 1, r, MAX_COL);
            gen.Merge();
            gen.FirstCell().Value = $"Generado: {DateTime.Now:yyyy-MM-dd HH:mm}";
            gen.Style.Font.FontSize = 9;
            gen.Style.Font.FontColor = XLColor.Gray;
            gen.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            r += 2;

            // ==========================
            // FILTROS
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Filtros", cSlate, MAX_COL);

            var desdeTxt = vm.Desde?.ToString("yyyy-MM-dd") ?? "-";
            var hastaTxt = vm.Hasta?.ToString("yyyy-MM-dd") ?? "-";

            var catTxt  = NombreLookup(vm.Categorias, vm.CategoriaId);
            var tipoTxt = NombreLookup(vm.Tipos, vm.TipoId);

            var invTxt = vm.InventarioId.HasValue
                ? (vm.Inventarios.FirstOrDefault(x => x.Id == vm.InventarioId.Value)?.Nombre ?? vm.InventarioId.Value.ToString())
                : "Todos";

            var soloInvTxt = vm.SoloInventario == null
                ? "Todos"
                : (vm.SoloInventario.Value ? "Sí (inventario)" : "No (gasto)");

            var estTxt = vm.SoloActivos == null
                ? "Todos"
                : (vm.SoloActivos.Value ? "Activos" : "Anulados");

            var compraTxt = vm.CompraId?.ToString() ?? "-";
            var topNTxt   = vm.TopN.ToString("N0");
            var qTxt      = Safe(vm.Q);

            // fila 1 (1..24)
            EscribirKVInline(ws, r,  1, "Desde",     desdeTxt, 2, 2, cSoftGray); // 1..4
            EscribirKVInline(ws, r,  5, "Hasta",     hastaTxt, 2, 2, cSoftGray); // 5..8
            EscribirKVInline(ws, r,  9, "Categoría", catTxt,   2, 6, cSoftGray); // 9..16
            EscribirKVInline(ws, r, 17, "Estatus",   estTxt,   2, 6, cSoftGray); // 17..24
            r++;

            // fila 2
            EscribirKVInline(ws, r,  1, "Tipo",        tipoTxt,     2, 6, cSoftGray); // 1..8
            EscribirKVInline(ws, r,  9, "Afectó inv.", soloInvTxt,  2, 6, cSoftGray); // 9..16
            EscribirKVInline(ws, r, 17, "CompraId",    compraTxt,   2, 2, cSoftGray); // 17..20
            EscribirKVInline(ws, r, 21, "Top N",       topNTxt,     2, 2, cSoftGray); // 21..24
            r++;

            // fila 3
            EscribirKVInline(ws, r,  1, "Inventario",  invTxt, 2, 10, cSoftGray); // 1..12
            EscribirKVInline(ws, r, 13, "Buscar (q)",  qTxt,   2, 10, cSoftGray); // 13..24
            r += 2;

            // ==========================
            // KPIs
            // ==========================
            r = EscribirTituloSeccion(ws, r, "KPIs", cTeal, MAX_COL);

            EscribirKpiCard(ws, r,  1,  6,  "Compras",              vm.Kpis.Compras.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r,  7,  12, "Gasto total",          vm.Kpis.GastoTotal.ToString("N2"), cSoftGray, isMoney: true);
            EscribirKpiCard(ws, r,  13, 18, "Compras a inventario",  vm.Kpis.ComprasInventario.ToString("N0"), cSoftGray);
            EscribirKpiCard(ws, r,  19, 24, "Cant. stock",          vm.Kpis.CantidadTotalInventario.ToString("0.####"), cSoftGray);

            // enfatiza gasto total
            ws.Range(r + 1, 7, r + 1, 12).Style.Font.FontColor = XLColor.FromHtml("#0F766E");
            r += 3;

            // extras
            EscribirKVInline(ws, r,  1,  "Gasto inventario", vm.Kpis.GastoInventario.ToString("N2"),    2, 4, cSoftGray); // 1..6
            EscribirKVInline(ws, r,  7,  "Gasto no invent.", vm.Kpis.GastoNoInventario.ToString("N2"),  2, 4, cSoftGray); // 7..12
            EscribirKVInline(ws, r,  13, "Compras no inv.",  vm.Kpis.ComprasNoInventario.ToString("N0"),2, 4, cSoftGray); // 13..18
            r += 2;

            // ==========================
            // TOP CATEGORIAS
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Top categorías", cBlueGray, MAX_COL);

            var dtCat = new DataTable("TopCategorias");
            dtCat.Columns.Add("Categoría");
            dtCat.Columns.Add("Compras", typeof(int));
            dtCat.Columns.Add("Total", typeof(decimal));

            foreach (var x in vm.TopCategorias)
                dtCat.Rows.Add(x.CategoriaNombre, x.Compras, x.Total);

            r = InsertarTablaAt(ws, r, 1, dtCat, "tblTopCategorias", cBlueGray, MAX_COL, cZebra, out var tblCat) + 2;

            if (tblCat != null)
            {
                AplicarFormatosTabla(tblCat, new()
                {
                    ["Compras"] = "0",
                    ["Total"]   = MoneyFmt(),
                });
            }

            // ==========================
            // TOP TIPOS
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Top tipos", cBlueGray, MAX_COL);

            var dtTipo = new DataTable("TopTipos");
            dtTipo.Columns.Add("Tipo");
            dtTipo.Columns.Add("Es inventario");
            dtTipo.Columns.Add("Compras", typeof(int));
            dtTipo.Columns.Add("Total", typeof(decimal));

            foreach (var x in vm.TopTipos)
                dtTipo.Rows.Add(x.TipoNombre, x.EsInventario == 1 ? "Sí" : "No", x.Compras, x.Total);

            r = InsertarTablaAt(ws, r, 1, dtTipo, "tblTopTipos", cBlueGray, MAX_COL, cZebra, out var tblTipo) + 2;

            if (tblTipo != null)
            {
                AplicarFormatosTabla(tblTipo, new()
                {
                    ["Compras"] = "0",
                    ["Total"]   = MoneyFmt(),
                });
            }

            // ==========================
            // TOP INVENTARIOS
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Top inventarios", cBlueGray, MAX_COL);

            var dtInv = new DataTable("TopInventarios");
            dtInv.Columns.Add("Inventario");
            dtInv.Columns.Add("Unidad");
            dtInv.Columns.Add("Compras", typeof(int));
            dtInv.Columns.Add("Cantidad", typeof(decimal));
            dtInv.Columns.Add("Total", typeof(decimal));

            foreach (var x in vm.TopInventarios)
                dtInv.Rows.Add(x.InventarioNombre, x.UnidadNombre ?? "-", x.Compras, x.Cantidad, x.Total);

            r = InsertarTablaAt(ws, r, 1, dtInv, "tblTopInventarios", cBlueGray, MAX_COL, cZebra, out var tblInv) + 2;

            if (tblInv != null)
            {
                AplicarFormatosTabla(tblInv, new()
                {
                    ["Compras"]   = "0",
                    ["Cantidad"]  = QtyFmt(),
                    ["Total"]     = MoneyFmt(),
                });
            }

            // ==========================
            // DETALLE
            // ==========================
            r = EscribirTituloSeccion(ws, r, "Detalle de transacciones", cBlueGray, MAX_COL);

            var dtDet = new DataTable("DetalleCompras");
            dtDet.Columns.Add("Fecha compra", typeof(DateTime));
            dtDet.Columns.Add("Fecha log", typeof(DateTime));
            dtDet.Columns.Add("Compra", typeof(int));
            dtDet.Columns.Add("Categoría");
            dtDet.Columns.Add("Tipo");
            dtDet.Columns.Add("Es inventario");
            dtDet.Columns.Add("Afectó inv.");
            dtDet.Columns.Add("Inventario");
            dtDet.Columns.Add("Unidad");
            dtDet.Columns.Add("Filamento tipo");
            dtDet.Columns.Add("Descripción");
            dtDet.Columns.Add("Operación");
            dtDet.Columns.Add("Transacción");
            dtDet.Columns.Add("Cant.", typeof(decimal));
            dtDet.Columns.Add("Costo U.", typeof(decimal));
            dtDet.Columns.Add("Total", typeof(decimal));
            dtDet.Columns.Add("Antes", typeof(decimal));
            dtDet.Columns.Add("Después", typeof(decimal));
            dtDet.Columns.Add("Estatus");

            // IMPORTANTE: guardo el orden para poder pintar “Anulados” por fila
            var detOrdered = vm.Detalle
                .OrderByDescending(x => x.FechaCompraFinal)
                .ThenByDescending(x => x.CompraId)
                .ToList();

            foreach (var x in detOrdered)
            {
                dtDet.Rows.Add(
                    x.FechaCompraFinal.Date,
                    x.FechaLogFinal,
                    x.CompraId,
                    x.CategoriaNombre,
                    x.TipoNombre,
                    x.EsInventario ? "Sí" : "No",
                    x.AfectoInventario ? "Sí" : "No",
                    x.InventarioNombre ?? "-",
                    x.InventarioUnidadNombre ?? "-",
                    x.FilamentoTipoNombre ?? "-",
                    x.CompraDescripcion ?? "-",
                    x.Operacion ?? "-",
                    x.TransaccionDescripcion ?? "-",
                    x.CantidadFinal,
                    x.CostoUnitarioFinal,
                    x.CostoTotalFinal,
                    x.InventarioAntes.HasValue ? x.InventarioAntes.Value : DBNull.Value,
                    x.InventarioDespues.HasValue ? x.InventarioDespues.Value : DBNull.Value,
                    x.EstaActivo ? "Activo" : "Anulado"
                );
            }

            var lastDet = InsertarTablaAt(ws, r, 1, dtDet, "tblComprasDetalle", cBlueGray, MAX_COL, cZebra, out var tblDet);

            if (tblDet != null)
            {
                // formatos numericos
                AplicarFormatosTabla(tblDet, new()
                {
                    ["Cant."]    = QtyFmt(),
                    ["Costo U."] = MoneyFmt(),
                    ["Total"]    = MoneyFmt(),
                    ["Antes"]    = QtyFmt(),
                    ["Después"]  = QtyFmt(),
                });

                // fechas (dateformat)
                foreach (var name in new[] { "Fecha compra", "Fecha log" })
                {
                    if (!TieneCampo(tblDet, name)) continue;
                    var pos = ObtenerPosCampo1Based(tblDet, name);
                    var rng = ObtenerRangoDatosColumna(tblDet, pos);
                    rng.Style.DateFormat.Format = "yyyy-mm-dd";
                    rng.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                }

                // wrap descripcion/transaccion
                if (TieneCampo(tblDet, "Descripción"))
                    tblDet.Field("Descripción").Column.Style.Alignment.WrapText = true;

                if (TieneCampo(tblDet, "Transacción"))
                    tblDet.Field("Transacción").Column.Style.Alignment.WrapText = true;

                // pintar anulados por fila completa
                if (tblDet.DataRange != null)
                {
                    var dr = tblDet.DataRange;
                    for (int i = 1; i <= dr.RowCount(); i++)
                    {
                        if (!detOrdered[i - 1].EstaActivo)
                        {
                            dr.Row(i).Style.Fill.BackgroundColor = cDangerBg;
                            dr.Row(i).Style.Font.FontColor = cDangerTx;
                        }
                    }
                }

                // freeze hasta el header del detalle (para que se queden titulo/filtros/kpis/top)
                ws.SheetView.FreezeRows(tblDet.RangeAddress.FirstAddress.RowNumber);

                // anchos minimos utiles
                // (ajusta a tu gusto)
                ws.Column(11).Width = Math.Max(ws.Column(11).Width, 34); // Descripcion
                ws.Column(13).Width = Math.Max(ws.Column(13).Width, 30); // Transaccion
                ws.Column(8).Width  = Math.Max(ws.Column(8).Width, 20);  // Inventario
            }

            // ==========================
            // Ajustes finales
            // ==========================
            ws.PageSetup.PageOrientation = XLPageOrientation.Landscape;
            ws.PageSetup.FitToPages(1, 0);
            ws.PageSetup.CenterHorizontally = true;

            // Ajusta según columnas reales usadas
            var usedCols = Math.Max(12, dtDet.Columns.Count);
            ws.Columns(1, Math.Min(usedCols, MAX_COL)).AdjustToContents(1, 80);

            using var ms = new MemoryStream();
            wb.SaveAs(ms);
            return ms.ToArray();
        }


    }
}