using ManejoPresupuestos.Models;
using ManejoPresupuestos.Servicios;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Controllers
{
    [Permiso("Compras")]
    public class ComprasController : Controller
    {
        private readonly IServicioUsuarios servicioUsuarios;

        private readonly IRepositorioComprasV2 repositorioCompras;
        private readonly IRepositorioCompraTiposV2 repositorioCompraTipos;
        private readonly IRepositorioCompraCategoriasV2 repositorioCompraCategorias;
        private readonly IRepositorioInventarios repositorioInventarios;

        public ComprasController(
            IServicioUsuarios servicioUsuarios,
            IRepositorioComprasV2 repositorioCompras,
            IRepositorioCompraTiposV2 repositorioCompraTipos,
            IRepositorioCompraCategoriasV2 repositorioCompraCategorias,
            IRepositorioInventarios repositorioInventarios
        )
        {
            this.servicioUsuarios = servicioUsuarios;
            this.repositorioCompras = repositorioCompras;
            this.repositorioCompraTipos = repositorioCompraTipos;
            this.repositorioCompraCategorias = repositorioCompraCategorias;
            this.repositorioInventarios = repositorioInventarios;
        }

        // ------------------------
        // COMPRAS
        // ------------------------
        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var compras = await repositorioCompras.ObtenerTodos(usuarioId);
            return View(compras); // Views/Compras/Index.cshtml
        }

        [HttpGet]
        public async Task<IActionResult> Crear()
        {
            var vm = new CompraV2FormViewModel
            {
                Tipos = await ObtenerTiposSelect(),
                Categorias = await ObtenerCategoriasSelect(),
                Inventarios = await ObtenerInventariosSelect()
            };

            return View(vm); // Views/Compras/Crear.cshtml
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Crear(CompraV2FormViewModel compra)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            // Validar catálogos
            var tipo = await repositorioCompraTipos.ObtenerPorId(compra.CompraTipoId);
            var categoria = await repositorioCompraCategorias.ObtenerPorId(compra.CompraCategoriaId);

            if (tipo is null || categoria is null || !tipo.EstaActivo || !categoria.EstaActivo)
                return RedirectToAction("NoEncontrado", "Home");

            // Reglas inventario
            if (tipo.EsInventario)
            {
                if (!compra.InventarioId.HasValue || compra.InventarioId.Value <= 0)
                    ModelState.AddModelError(nameof(compra.InventarioId), "Selecciona un inventario.");

                if (compra.Cantidad <= 0)
                    ModelState.AddModelError(nameof(compra.Cantidad), "Cantidad debe ser mayor a 0.");

                if (compra.CostoUnitario <= 0)
                    ModelState.AddModelError(nameof(compra.CostoUnitario), "Costo unitario debe ser mayor a 0.");

                compra.CostoTotal = compra.Cantidad * compra.CostoUnitario;
            }
            else
            {
                compra.InventarioId = null;
                compra.Cantidad = 0;
                compra.CostoUnitario = 0;

                if (compra.CostoTotal <= 0)
                    ModelState.AddModelError(nameof(compra.CostoTotal), "Costo total debe ser mayor a 0.");
            }

            if (!ModelState.IsValid)
            {
                compra.Tipos = await ObtenerTiposSelect();
                compra.Categorias = await ObtenerCategoriasSelect();
                compra.Inventarios = await ObtenerInventariosSelect();
                return View(compra);
            }

            var compraEntity = new CompraV2
            {
                Descripcion = compra.Descripcion,
                CompraTipoId = compra.CompraTipoId,
                CompraCategoriaId = compra.CompraCategoriaId,

                // Sin filamentos en UI. Si tu entidad todavía tiene FilamentoTipoId nullable,
                // lo puedes dejar así. Si ya lo quitaste del modelo, borra esta línea.
                FilamentoTipoId = null,

                InventarioId = compra.InventarioId,
                Cantidad = compra.Cantidad,
                CostoUnitario = compra.CostoUnitario,
                CostoTotal = compra.CostoTotal,
                FechaCreacion = compra.FechaCreacion
            };

            await repositorioCompras.Crear(usuarioId, compraEntity);
            await repositorioCompras.CompraLogTransaccion(usuarioId, compraEntity);

            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Editar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var compra = await repositorioCompras.ObtenerPorId(usuarioId, id);

            if (compra is null)
                return RedirectToAction("NoEncontrado", "Home");

            var vm = new CompraV2FormViewModel
            {
                CompraId = compra.CompraId,
                Descripcion = compra.Descripcion,
                CompraTipoId = compra.CompraTipoId,
                CompraCategoriaId = compra.CompraCategoriaId,

                InventarioId = compra.InventarioId,
                Cantidad = compra.Cantidad,
                CostoUnitario = compra.CostoUnitario,
                CostoTotal = compra.CostoTotal,
                FechaCreacion = compra.FechaCreacion,

                Tipos = await ObtenerTiposSelect(),
                Categorias = await ObtenerCategoriasSelect(),
                Inventarios = await ObtenerInventariosSelect()
            };

            return View(vm); // Views/Compras/Editar.cshtml
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Editar(CompraV2FormViewModel compra)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();

            var existe = await repositorioCompras.ObtenerPorId(usuarioId, compra.CompraId);
            if (existe is null)
                return RedirectToAction("NoEncontrado", "Home");

            var tipo = await repositorioCompraTipos.ObtenerPorId(compra.CompraTipoId);
            var categoria = await repositorioCompraCategorias.ObtenerPorId(compra.CompraCategoriaId);

            if (tipo is null || categoria is null || !tipo.EstaActivo || !categoria.EstaActivo)
                return RedirectToAction("NoEncontrado", "Home");

            if (tipo.EsInventario)
            {
                if (!compra.InventarioId.HasValue || compra.InventarioId.Value <= 0)
                    ModelState.AddModelError(nameof(compra.InventarioId), "Selecciona un inventario.");

                if (compra.Cantidad <= 0)
                    ModelState.AddModelError(nameof(compra.Cantidad), "Cantidad debe ser mayor a 0.");

                if (compra.CostoUnitario <= 0)
                    ModelState.AddModelError(nameof(compra.CostoUnitario), "Costo unitario debe ser mayor a 0.");

                compra.CostoTotal = compra.Cantidad * compra.CostoUnitario;
            }
            else
            {
                compra.InventarioId = null;
                compra.Cantidad = 0;
                compra.CostoUnitario = 0;

                if (compra.CostoTotal <= 0)
                    ModelState.AddModelError(nameof(compra.CostoTotal), "Costo total debe ser mayor a 0.");
            }

            if (!ModelState.IsValid)
            {
                compra.Tipos = await ObtenerTiposSelect();
                compra.Categorias = await ObtenerCategoriasSelect();
                compra.Inventarios = await ObtenerInventariosSelect();
                return View(compra);
            }

            var entity = new CompraV2
            {
                CompraId = compra.CompraId,
                Descripcion = compra.Descripcion,
                CompraTipoId = compra.CompraTipoId,
                CompraCategoriaId = compra.CompraCategoriaId,

                FilamentoTipoId = null, // quítalo si ya no existe en tu modelo

                InventarioId = compra.InventarioId,
                Cantidad = compra.Cantidad,
                CostoUnitario = compra.CostoUnitario,
                CostoTotal = compra.CostoTotal,
                FechaCreacion = compra.FechaCreacion
            };

            await repositorioCompras.Actualizar(usuarioId, entity);
            await repositorioCompras.CompraLogTransaccion(usuarioId, entity);

            return RedirectToAction("Index");
        }

        [HttpGet]
        public async Task<IActionResult> Borrar(int id)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var compra = await repositorioCompras.ObtenerPorId(usuarioId, id);

            if (compra is null)
                return RedirectToAction("NoEncontrado", "Home");

            return View(compra); // Views/Compras/Borrar.cshtml
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> BorrarCompra(int compraId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var compra = await repositorioCompras.ObtenerPorId(usuarioId, compraId);

            if (compra is null)
                return RedirectToAction("NoEncontrado", "Home");

            await repositorioCompras.Borrar(usuarioId, compraId);
            return RedirectToAction("Index");
        }

        // ------------------------
        // CATÁLOGOS (V2) - CATEGORÍAS
        // ------------------------
        [HttpGet]
        public async Task<IActionResult> Categorias()
        {
            var categorias = await repositorioCompraCategorias.ObtenerTodosIncluyendoInactivos();
            return View(categorias); // Views/Compras/Categorias.cshtml
        }

        [HttpGet]
        public IActionResult CrearCategoria() => View(new CompraCategoriaV2());

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CrearCategoria(CompraCategoriaV2 categoria)
        {
            if (!ModelState.IsValid) return View(categoria);

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioCompraCategorias.Crear(usuarioId, categoria);
            return RedirectToAction("Categorias");
        }

        [HttpGet]
        public async Task<IActionResult> EditarCategoria(int id)
        {
            var categoria = await repositorioCompraCategorias.ObtenerPorId(id);
            if (categoria is null) return RedirectToAction("NoEncontrado", "Home");
            return View(categoria);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditarCategoria(CompraCategoriaV2 categoria)
        {
            if (!ModelState.IsValid) return View(categoria);

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioCompraCategorias.Actualizar(usuarioId, categoria);
            return RedirectToAction("Categorias");
        }

        [HttpGet]
        public async Task<IActionResult> BorrarCategoriaForm(int id)
        {
            var categoria = await repositorioCompraCategorias.ObtenerPorId(id);
            if (categoria is null) return RedirectToAction("NoEncontrado", "Home");
            return View(categoria);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> BorrarCategoria(int compraCategoriaId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioCompraCategorias.Borrar(usuarioId, compraCategoriaId);
            return RedirectToAction("Categorias");
        }

        // ------------------------
        // CATÁLOGOS (V2) - TIPOS
        // ------------------------
        [HttpGet]
        public async Task<IActionResult> Tipos()
        {
            var tipos = await repositorioCompraTipos.ObtenerTodosIncluyendoInactivos();
            return View(tipos); // Views/Compras/Tipos.cshtml
        }

        [HttpGet]
        public IActionResult CrearTipo() => View(new CompraTipoV2());

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CrearTipo(CompraTipoV2 tipo)
        {
            if (!ModelState.IsValid) return View(tipo);

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioCompraTipos.Crear(usuarioId, tipo);
            return RedirectToAction("Tipos");
        }

        [HttpGet]
        public async Task<IActionResult> EditarTipo(int id)
        {
            var tipo = await repositorioCompraTipos.ObtenerPorId(id);
            if (tipo is null) return RedirectToAction("NoEncontrado", "Home");
            return View(tipo);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditarTipo(CompraTipoV2 tipo)
        {
            if (!ModelState.IsValid) return View(tipo);

            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioCompraTipos.Actualizar(usuarioId, tipo);
            return RedirectToAction("Tipos");
        }

        [HttpGet]
        public async Task<IActionResult> BorrarTipoForm(int id)
        {
            var tipo = await repositorioCompraTipos.ObtenerPorId(id);
            if (tipo is null) return RedirectToAction("NoEncontrado", "Home");
            return View(tipo);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> BorrarTipo(int compraTipoId)
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            await repositorioCompraTipos.Borrar(usuarioId, compraTipoId);
            return RedirectToAction("Tipos");
        }

        // ------------------------
        // SELECT LIST HELPERS
        // ------------------------
        private async Task<IEnumerable<SelectListItem>> ObtenerTiposSelect()
        {
            var tipos = await repositorioCompraTipos.ObtenerTodosActivos();
            return tipos.Select(t => new SelectListItem(t.Nombre, t.CompraTipoId.ToString()));
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerCategoriasSelect()
        {
            var cats = await repositorioCompraCategorias.ObtenerTodosActivos();
            return cats.Select(c => new SelectListItem(c.Nombre, c.CompraCategoriaId.ToString()));
        }

        private async Task<IEnumerable<SelectListItem>> ObtenerInventariosSelect()
        {
            var usuarioId = servicioUsuarios.ObtenerUsuarioId();
            var invs = await repositorioInventarios.ObtenerTodos(usuarioId);

            string Label(dynamic i)
            {
                var unidad = (string)i.InventarioUnidad;
                var suf = unidad == "Unidad" ? "unidad" : "g";
                return $"{i.InventarioNombre} ({i.InventarioColor}) - {suf}";
            }

            return invs.Select(i => new SelectListItem(Label(i), i.InventarioId.ToString()));
        }
    }
}