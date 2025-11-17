using Microsoft.AspNetCore.Mvc.Rendering;

namespace ManejoPresupuestos.Models
{
    public class CompraCreacionViewModel : Compra
    {
        public IEnumerable<SelectListItem> Categorias { get; set; }
        public IEnumerable<SelectListItem> Tipos { get; set; }
        public IEnumerable<SelectListItem> FilamentoTipos { get; set; }
    }
}
