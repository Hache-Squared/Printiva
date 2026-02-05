using ClosedXML.Excel;
using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;

namespace ManejoPresupuestos.Servicios
{
    public interface ITransformToReport
    {
        byte[] GenerarExcelProduccionWip(ReporteProduccionWipViewModel vm);
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
            // Sheet: Antigüedad (cola)
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

            // Resaltar atrasados en Detalle (columna 12 = "Atrasado")
            // var colAtrasado = tblDet.Field("Atrasado").Column;
            // var rngAtrasado = colAtrasado.DataCells;
            // rngAtrasado.AddConditionalFormat()
            //     .WhenEquals("Sí")
            //     .Fill.SetBackgroundColor(XLColor.FromHtml("#FFF3CD"));

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

    }
}