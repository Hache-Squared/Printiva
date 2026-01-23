using AutoMapper;
using DocumentFormat.OpenXml.Office2010.Excel;
using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Controllers
{
    public class VentasController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;
        private readonly IRepositorioClientes repositorioClientes;
        private readonly IRepositorioRecetas repositorioRecetas;
        private readonly IRepositorioVentas repositorioVentas;
        private readonly IRepositorioVentaRecetas repositorioVentaRecetas;
        private readonly IMapper mapper;

        public VentasController(
            IServicioUsuarios servicioUsuarios,
            IRepositorioClientes repositorioClientes,
            IRepositorioRecetas repositorioRecetas,
            IRepositorioVentas repositorioVentas,
            IRepositorioVentaRecetas repositorioVentaRecetas,
            IMapper mapper)
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioClientes = repositorioClientes;
            this.repositorioRecetas = repositorioRecetas;
            this.repositorioVentas = repositorioVentas;
            this.repositorioVentaRecetas = repositorioVentaRecetas;
            this.mapper = mapper;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var ventas = await repositorioVentas.ObtenerTodos(usuarioId);
            return View(ventas);
        }

        [HttpGet]
        public async Task<IActionResult> Crear()
        {
            var modelo = new VentaCreacionViewModel
            {
                Clientes = await ObtenerClientes(),
                Recetas = await ObtenerRecetasSelectList()
            };

            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Crear(VentaCreacionViewModel venta)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            var cliente = await repositorioClientes.ObtenerPorId(venta.ClienteId ?? -1, usuarioId);
            if (cliente is null)
                return RedirectToAction("NoEncontrado", "Home");

            if (!ModelState.IsValid)
            {
                venta.Clientes = await ObtenerClientes();
                venta.Recetas = await ObtenerRecetasSelectList();
                return View(venta);
            }

            venta.UsuarioId = usuarioId;
            await repositorioVentas.Crear(venta);

            return RedirectToAction("Editar", new { id = venta.VentaId });
        }

        [HttpGet]
        public async Task<IActionResult> Editar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var venta = await repositorioVentas.ObtenerPorId(usuarioId, id);

            if (venta is null)
                return RedirectToAction("NoEncontrado", "Home");

            var modelo = mapper.Map<VentaCreacionViewModel>(venta);
            modelo.Clientes = await ObtenerClientes();
            modelo.Recetas = await ObtenerRecetasSelectList();

            modelo.VentaRecetas = await repositorioVentaRecetas.ObtenerPorVentaId(id, usuarioId);

            return View(modelo);
        }

        [HttpPost]
        public async Task<IActionResult> Editar(VentaCreacionViewModel ventaEditar)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var venta = await repositorioVentas.ObtenerPorId(usuarioId, ventaEditar.VentaId);

            ventaEditar.CostoTotal = venta.CostoTotal;

            if (venta is null)
                return RedirectToAction("NoEncontrado", "Home");

            var cliente = await repositorioClientes.ObtenerPorId(ventaEditar.ClienteId ?? -1, usuarioId);
            if (cliente is null)
                return RedirectToAction("NoEncontrado", "Home");

            if (!ModelState.IsValid)
            {
                ventaEditar.Clientes = await ObtenerClientes();
                ventaEditar.Recetas = await ObtenerRecetasSelectList();
                return View(ventaEditar);
            }

            ventaEditar.UsuarioId = usuarioId;
            await repositorioVentas.Actualizar(usuarioId, ventaEditar);

            await repositorioVentas.VentaLogTransaccion(usuarioId, ventaEditar);

            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Borrar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var venta = await repositorioVentas.ObtenerPorId(usuarioId, id);
            if (venta is null)
                return RedirectToAction("NoEncontrado", "Home");

            return View(venta);
        }

        [HttpPost]
        public async Task<IActionResult> BorrarVenta(int ventaId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var venta = await repositorioVentas.ObtenerPorId(usuarioId, ventaId);
            if (venta is null)
                return RedirectToAction("NoEncontrado", "Home");

            await repositorioVentas.Borrar(usuarioId, ventaId);
            return RedirectToAction("Index");
        }

        [HttpGet]
        public IActionResult CrearClientePartial()
        {
            return PartialView("_CrearClientePartial", new Cliente());
        }

        [HttpPost]
        public async Task<IActionResult> CrearCliente(Cliente cliente)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            if (!ModelState.IsValid)
            {
                return Json(new { success = false, message = "Datos inválidos" });
            }

            await repositorioClientes.Crear(usuarioId, cliente);

            var nuevoCliente = new
            {
                id = cliente.ClienteId,
                texto = $"{cliente.Nombre}".Trim()
            };

            return Json(new { success = true, cliente = nuevoCliente });
        }

        [HttpPost]
        public async Task<IActionResult> CrearVentaReceta(VentaRecetaCreacionViewModel modelo)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            if (!ModelState.IsValid)
            {
                modelo.Recetas = await ObtenerRecetasSelectList();
                return PartialView("_CrearVentaRecetaPartial", modelo);
            }

            var ventaExistente = await repositorioVentas.ObtenerPorId(usuarioId, modelo.VentaId);
            if (ventaExistente == null)
                return Json(new { success = false, message = "Venta no encontrada" });

            var ventaReceta = new VentaReceta
            {
                VentaId = modelo.VentaId,
                RecetaId = modelo.RecetaId,
                Cantidad = modelo.Cantidad,
                CostoUnitario = modelo.CostoUnitario
            };

            await repositorioVentaRecetas.Crear(ventaReceta);

            var partidas = await repositorioVentaRecetas.ObtenerPorVentaId(modelo.VentaId, usuarioId);
            var nuevoTotal = partidas.Sum(p => p.Cantidad * p.CostoUnitario);

            ventaExistente.CostoTotal = nuevoTotal;

            await repositorioVentas.Actualizar(usuarioId, ventaExistente);

            return Json(new { success = true });
        }

        public class BorrarVentaRecetaRequest
        {
            public int VentaRecetaId { get; set; }
        }

        [HttpPost]
        public async Task<IActionResult> BorrarVentaReceta([FromBody] BorrarVentaRecetaRequest request)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            var partida = await repositorioVentaRecetas.ObtenerPorId(request.VentaRecetaId, usuarioId);
            if (partida == null)
                return Json(new { success = false, message = "Partida no encontrada" });

            await repositorioVentaRecetas.Borrar(request.VentaRecetaId, usuarioId);

            // Recalcular el nuevo total
            var partidasRestantes = await repositorioVentaRecetas.ObtenerPorVentaId(partida.VentaId, usuarioId);
            var nuevoTotal = partidasRestantes.Sum(p => p.Cantidad * p.CostoUnitario);

            // Actualizar la venta con el nuevo total
            var venta = await repositorioVentas.ObtenerPorId(usuarioId, partida.VentaId);
            if (venta != null)
            {
                venta.CostoTotal = nuevoTotal;
                await repositorioVentas.Actualizar(usuarioId, venta);
            }

            return Json(new { success = true });
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerClientes()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var clientes = await repositorioClientes.ObtenerTodos(usuarioId);
            return clientes
                .Select(c => new SelectListItem($"{c.Nombre}", c.ClienteId.ToString()))
                .Prepend(new SelectListItem("— Seleccionar cliente —", "", true));
        }

        private async Task<List<SelectListItem>> ObtenerRecetasSelectList()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var param = new ParametroObtenerRecetas()
            {
                ElementoObtenerId = 0,
                LoginId = usuarioId
            };

            var recetas = await repositorioRecetas.ObtenerTodos(param);
            return recetas
                .Select(r => new SelectListItem(r.Nombre, r.RecetaId.ToString()))
                .ToList();
        }
    }
}