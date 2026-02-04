using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;

namespace ManejoPresupuestos.Controllers
{
    public class ReportesController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioReportes repositorioReportes;

        public ReportesController(
            IServicioUsuarios servicioUsuarios,
            IRepositorioReportes repositorioReportes
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioReportes = repositorioReportes;
        }

        [HttpGet]
        public IActionResult Index()
        {
            return View();
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
    }
}
