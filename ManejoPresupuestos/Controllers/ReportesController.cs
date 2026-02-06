using ClosedXML.Excel;
using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;

namespace ManejoPresupuestos.Controllers
{
    [Permiso("Reportes")]
    public class ReportesController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioReportes repositorioReportes;
        private readonly ITransformToReport transformToReport;

        public ReportesController(
            IServicioUsuarios servicioUsuarios,
            IRepositorioReportes repositorioReportes,
            ITransformToReport transformToReport
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioReportes = repositorioReportes;
            this.transformToReport = transformToReport;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var vm = await repositorioReportes.ObtenerIndexResumen(usuarioId, diasUrgente: 3, topN: 10);
            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> Consumo(DateTime? desde, DateTime? hasta, int? pedidoId, int? inventarioId, int? usuarioId, int? productoId, int? recetaId)
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var vm = await repositorioReportes.ConsumoInventario(
                loginId,
                desde,
                hasta,
                pedidoId,
                inventarioId,
                usuarioId,
                productoId,
                recetaId
            );

            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> Produccion(
            DateTime? desde,
            DateTime? hasta,
            int? clienteId,
            int? pedidoId,
            int? estatusId,
            int? impresoraId,
            bool? soloWip,
            bool? soloAtrasados,
            bool? sinImpresora,
            int? minDiasCola,
            string? q
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var vm = await repositorioReportes.ProduccionWipDashboard(
                loginId,
                desde,
                hasta,
                clienteId,
                pedidoId,
                estatusId,
                impresoraId,
                soloWip ?? true,          // default: tablero WIP
                soloAtrasados ?? false,
                sinImpresora ?? false,
                minDiasCola,
                q
            );

            return View(vm);
        }

        [HttpGet]
        public async Task<FileResult> ExportarProduccionExcel(
            DateTime? desde,
            DateTime? hasta,
            int? clienteId,
            int? pedidoId,
            int? estatusId,
            int? impresoraId,
            bool? soloWip,
            bool? soloAtrasados,
            bool? sinImpresora,
            int? minDiasCola,
            string? q
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var vm = await repositorioReportes.ProduccionWipDashboard(
                loginId,
                desde,
                hasta,
                clienteId,
                pedidoId,
                estatusId,
                impresoraId,
                soloWip ?? true,
                soloAtrasados ?? false,
                sinImpresora ?? false,
                minDiasCola,
                q
            );

            var bytes = transformToReport.GenerarExcelProduccionWip(vm);

            var d1 = (vm.Desde ?? DateTime.Today).ToString("yyyyMMdd");
            var d2 = (vm.Hasta ?? DateTime.Today).ToString("yyyyMMdd");
            var nombreArchivo = $"Produccion_WIP_Carga_{d1}-{d2}.xlsx";

            return File(
                bytes,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                nombreArchivo
            );
        }

        [HttpGet]
        public async Task<IActionResult> Costeo(DateTime? desde, DateTime? hasta, int? pedidoId)
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();
            var vm = await repositorioReportes.Costeo(loginId, desde, hasta, pedidoId);
            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> Pedido360(int? pedidoId)
        {
            // Para que puedas abrir la pantalla sin parámetros
            if (!pedidoId.HasValue || pedidoId.Value <= 0)
            {
                return View(new ReportePedido360ViewModel { PedidoId = pedidoId ?? 0 });
            }

            var loginId = servicioUsuarios.ObtenerUsuarioId();
            var vm = await repositorioReportes.Pedido360(loginId, pedidoId.Value);

            return View(vm);
        }

        [HttpGet]
        public async Task<FileResult> ExportarPedido360Excel(int? pedidoId)
        {
            if (!pedidoId.HasValue || pedidoId.Value <= 0)
            {
                var empty = transformToReport.GenerarExcelPedido360(new ReportePedido360ViewModel
                {
                    PedidoId = pedidoId ?? 0,
                    Mensaje = "Debes indicar un PedidoId válido."
                });

                return File(
                    empty,
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    $"Pedido360_INVALIDO_{DateTime.Today:yyyyMMdd}.xlsx"
                );
            }

            var loginId = servicioUsuarios.ObtenerUsuarioId();
            var vm = await repositorioReportes.Pedido360(loginId, pedidoId.Value);

            var bytes = transformToReport.GenerarExcelPedido360(vm);
            var nombre = $"Pedido360_{pedidoId.Value}_{DateTime.Today:yyyyMMdd}.xlsx";

            return File(bytes,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                nombre
            );
        }

        [HttpGet]
        public async Task<IActionResult> PedidosOperativos(
            DateTime? desde,
            DateTime? hasta,
            int? pedidoEstatusId,
            int? clienteId,
            bool? atrasados,
            int? produccionEstatusId,
            string? canal
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var vm = await repositorioReportes.PedidosOperativos(
                loginId,
                desde,
                hasta,
                pedidoEstatusId,
                clienteId,
                atrasados,
                produccionEstatusId,
                canal
            );

            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> PedidosOperativosExcel(
            DateTime? desde,
            DateTime? hasta,
            int? pedidoEstatusId,
            int? clienteId,
            bool? atrasados,
            int? produccionEstatusId,
            string? canal
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            // Reusa EXACTAMENTE el mismo armado del VM que la vista
            var vm = await repositorioReportes.PedidosOperativos(
                loginId,
                desde,
                hasta,
                pedidoEstatusId,
                clienteId,
                atrasados,
                produccionEstatusId,
                canal
            );

            var bytes = transformToReport.GenerarExcelPedidosOperativos(vm);

            var d = (vm.Desde).Date;
            var h = (vm.Hasta).Date;
            var fileName = $"PedidosOperativos_{d:yyyyMMdd}_{h:yyyyMMdd}.xlsx";

            return File(
                bytes,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                fileName
            );
        }

        [HttpGet]
        public async Task<IActionResult> Cxc(
            DateTime? desde,
            DateTime? hasta,
            int? clienteId,
            int? pedidoId,
            bool? soloVencidos,
            int? bucketId,
            string? metodo,
            decimal? minSaldo
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var vm = await repositorioReportes.CxcAging(
                loginId,
                desde,
                hasta,
                clienteId,
                pedidoId,
                soloVencidos ?? false,
                bucketId,
                metodo,
                minSaldo
            );

            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> CxcExcel(
            DateTime? desde,
            DateTime? hasta,
            int? clienteId,
            int? pedidoId,
            bool? soloVencidos,
            int? bucketId,
            string? metodo,
            decimal? minSaldo
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var vm = await repositorioReportes.CxcAging(
                loginId,
                desde,
                hasta,
                clienteId,
                pedidoId,
                soloVencidos ?? false,
                bucketId,
                metodo,
                minSaldo
            );

            var bytes = transformToReport.GenerarExcelPagosPendientes(vm);

            var fileName = $"PagosPendientes_{vm.Desde:yyyyMMdd}_{vm.Hasta:yyyyMMdd}.xlsx";
            return File(
                bytes,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                fileName
            );
        }

        [HttpGet]
        public async Task<IActionResult> Cotizaciones(
            DateTime? desde,
            DateTime? hasta,
            int? clienteId,
            int? cotizacionEstatusId,
            bool? soloConvertidas,
            bool? soloUltimaPorPedido,
            decimal? minMonto,
            string? q
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var vm = await repositorioReportes.CotizacionesSeguimiento(
                loginId,
                desde,
                hasta,
                clienteId,
                cotizacionEstatusId,
                soloConvertidas ?? false,
                soloUltimaPorPedido ?? false,
                minMonto,
                q
            );

            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> CotizacionesExcel(
            DateTime? desde,
            DateTime? hasta,
            int? clienteId,
            int? cotizacionEstatusId,
            bool? soloConvertidas,
            bool? soloUltimaPorPedido,
            decimal? minMonto,
            string? q
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            // MISMO repo que arma el VM del reporte (con defaults adentro)
            var vm = await repositorioReportes.CotizacionesSeguimiento(
                loginId,
                desde,
                hasta,
                clienteId,
                cotizacionEstatusId,
                soloConvertidas ?? false,
                soloUltimaPorPedido ?? false,
                minMonto,
                q
            );

            var bytes = transformToReport.GenerarExcelCotizacionesSeguimiento(vm);

            var fileName = $"CotizacionesSeguimiento_{vm.Desde:yyyyMMdd}_{vm.Hasta:yyyyMMdd}.xlsx";
            return File(
                bytes,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                fileName
            );
        }

        [HttpGet]
        public async Task<IActionResult> ProduccionUtilizacion(
            DateTime? desde,
            DateTime? hasta,
            int? impresoraId,
            bool incluirEnCurso = true,
            bool incluirSinImpresora = true,
            string? q = null
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var vm = await repositorioReportes.ProduccionUtilizacionImpresoras(
                loginId,
                desde,
                hasta,
                impresoraId,
                incluirEnCurso,
                incluirSinImpresora,
                q
            );

            return View(vm); // Views/Reportes/ProduccionUtilizacion.cshtml
        }

        [HttpGet]
        public async Task<IActionResult> ProduccionUtilizacionExcel(
            DateTime? desde,
            DateTime? hasta,
            int? impresoraId,
            bool incluirEnCurso = true,
            bool incluirSinImpresora = true,
            string? q = null
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var vm = await repositorioReportes.ProduccionUtilizacionImpresoras(
                loginId,
                desde,
                hasta,
                impresoraId,
                incluirEnCurso,
                incluirSinImpresora,
                q
            );

            var bytes = transformToReport.GenerarExcelProduccionUtilizacion(vm);

            var d = (vm.Desde ?? DateTime.Today.AddDays(-30)).Date;
            var h = (vm.Hasta ?? DateTime.Today).Date;

            var fileName = $"ProduccionUtilizacion_{d:yyyyMMdd}_{h:yyyyMMdd}.xlsx";
            return File(bytes,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                fileName);
        }

        [HttpGet]
        public async Task<IActionResult> InventarioConsumoMejorado(
            DateTime? desde,
            DateTime? hasta,
            int? pedidoId,
            int? productoId,
            int? recetaId,
            int? inventarioId,
            string periodo = "month",
            int topN = 10,
            string? q = null
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var vm = await repositorioReportes.InventarioConsumoMejorado(
                loginId,
                desde, hasta,
                pedidoId, productoId, recetaId, inventarioId,
                periodo,
                topN,
                q
            );

            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> InventarioConsumoMejoradoExcel(
            DateTime? desde,
            DateTime? hasta,
            int? pedidoId,
            int? productoId,
            int? recetaId,
            int? inventarioId,
            string periodo = "month",
            int topN = 10,
            string? q = null
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var vm = await repositorioReportes.InventarioConsumoMejorado(
                loginId,
                desde, hasta,
                pedidoId, productoId, recetaId, inventarioId,
                periodo ?? "month",
                topN <= 0 ? 10 : topN,
                q
            );

            var bytes = transformToReport.GenerarExcelInventarioConsumoMejorado(vm);

            var d = (desde ?? DateTime.Today.AddDays(-30)).Date;
            var h = (hasta ?? DateTime.Today).Date;

            var fileName = $"InventarioConsumoMejorado_{d:yyyyMMdd}_{h:yyyyMMdd}.xlsx";
            return File(
                bytes,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                fileName
            );
        }

        
        [HttpGet]
        public async Task<IActionResult> ComprasHistorico(
            DateTime? desde,
            DateTime? hasta,
            int? compraId,
            int? categoriaId,
            int? tipoId,
            int? inventarioId,
            bool? soloActivos,
            bool? soloInventario,
            int topN = 10,
            string? q = null
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            var vm = await repositorioReportes.ComprasHistorico(
                loginId,
                desde,
                hasta,
                compraId,
                categoriaId,
                tipoId,
                inventarioId,
                soloActivos,
                soloInventario,
                topN,
                q
            );

            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> ComprasHistoricoExcel(
            DateTime? desde,
            DateTime? hasta,
            int? compraId,
            int? categoriaId,
            int? tipoId,
            int? inventarioId,
            bool? soloActivos,
            bool? soloInventario,
            int topN = 10,
            string? q = null
        )
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();

            //  NO default 30 dias: respeta null tal cual (igual que la vista si así la manejas)
            var d = desde?.Date;
            var h = hasta?.Date;

            var vm = await repositorioReportes.ComprasHistorico(
                loginId,
                d,
                h,
                compraId,
                categoriaId,
                tipoId,
                inventarioId,
                soloActivos,
                soloInventario,
                topN <= 0 ? 10 : topN,
                q
            );

            var bytes = transformToReport.GenerarExcelComprasHistorico(vm);

            var now = DateTime.Now;

            var dName = d?.ToString("yyyyMMdd") ?? now.ToString("yyyyMMdd");
            var hName = h?.ToString("yyyyMMdd") ?? now.ToString("yyyyMMdd_HHmm");

            var fileName = $"ComprasHistorico_{dName}_{hName}.xlsx";

            return File(
                bytes,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                fileName
            );
        }
    }
}
