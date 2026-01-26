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
        public async Task<IActionResult> Produccion()
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();
            var vm = await repositorioReportes.ProduccionDashboard(loginId);
            return View(vm);
        }

        [HttpGet]
        public async Task<IActionResult> Costeo(DateTime? desde, DateTime? hasta, int? pedidoId)
        {
            var loginId = servicioUsuarios.ObtenerUsuarioId();
            var vm = await repositorioReportes.Costeo(loginId, desde, hasta, pedidoId);
            return View(vm);
        }
    }
}
